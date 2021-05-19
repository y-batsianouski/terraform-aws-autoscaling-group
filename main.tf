locals {
  asg_override_instance_types = [for i in lookup(lookup(var.asg_mixed_instances_policy, "launch_template", {}), "override", []) : i["instance_type"] if lookup(i, "instance_type", "") != ""]
  instance_types              = length(local.asg_override_instance_types) > 0 ? local.asg_override_instance_types : [var.lt_instance_type]

  lt_ebs_optimized = var.lt_ebs_optimized_auto ? length(matchkeys(
    data.aws_ec2_instance_type.this.*.ebs_optimized_support,
    data.aws_ec2_instance_type.this.*.ebs_optimized_support,
    ["unsupported"]
  )) == 0 : var.lt_ebs_optimized

  lt_root_block_device = length(keys(var.lt_root_block_device)) == 0 || var.lc_use == true ? [] : [{
    device_name  = data.aws_ami.this[0].root_device_name,
    virtual_name = lookup(var.lt_root_block_device, "virtual_name", null),
    no_device    = lookup(var.lt_root_block_device, "no_device", null),
    ebs = data.aws_ami.this[0].root_device_type == "instance-store" ? {} : {
      delete_on_termination = lookup(var.lt_root_block_device, "delete_on_termination", false),
      encrypted             = lookup(var.lt_root_block_device, "encrypted", false),
      iops                  = lookup(var.lt_root_block_device, "iops", null),
      kms_key_id            = lookup(var.lt_root_block_device, "kms_key_id", null),
      snapshot_id           = lookup(var.lt_root_block_device, "snapshot_id", null),
      volume_size           = lookup(var.lt_root_block_device, "volume_size", null),
      volume_type           = lookup(var.lt_root_block_device, "volume_type", null),
    }
  }]

  lt_block_device_mappings = var.lt_block_device_mappings

  lt_network_interfaces = length(var.lt_network_interfaces) == 0 ? var.lt_associate_public_ip_address ? [{
    associate_public_ip_address = var.lt_associate_public_ip_address,
    srcurity_groups             = join(",", var.lt_vpc_security_group_ids),
    delete_on_termination       = true,
    description                 = "Default network interface"
  }] : [] : var.lt_network_interfaces

  lt_instance_tag_spec = length(keys(var.tags)) > 0 ? [
    {
      resource_type = "instance",
      tags = merge(
        { Name = var.asg_name_prefix != "" ? var.asg_name_prefix : var.asg_name != "" ? var.asg_name : var.name },
        var.tags
      )
    },
    {
      resource_type = "volume",
      tags = merge(
        { Name = var.asg_name_prefix != "" ? var.asg_name_prefix : var.asg_name != "" ? var.asg_name : var.name },
        var.tags
      )
    }
  ] : []

  lt_spot_request_tag_spec = length(keys(var.tags)) > 0 && length(keys(local.asg_instances_distribution)) > 0 && lookup(local.asg_instances_distribution, "on_demand_percentage_above_base_capacity", 100) == 0 && lookup(local.asg_instances_distribution, "on_demand_base_capacity", 100) == 0 ? [{
    resource_type = "spot-instances-request",
    tags = merge(
      { Name = var.asg_name_prefix != "" ? var.asg_name_prefix : var.asg_name != "" ? var.asg_name : var.name },
      var.tags
    )
  }] : []

  lt_gpu_tag_spec = length(keys(var.tags)) > 0 && length(keys(var.lt_elastic_gpu_specifications)) > 0 ? [{
    resource_type = "elastic-gpu",
    tags = merge(
      { Name = var.asg_name_prefix != "" ? var.asg_name_prefix : var.asg_name != "" ? var.asg_name : var.name },
      var.tags
    )
  }] : []

  lt_tag_specifications = concat(var.lt_tag_specifications, length(var.lt_tag_specifications) > 0 ? [] : concat(
    local.lt_instance_tag_spec,
    local.lt_spot_request_tag_spec,
    local.lt_gpu_tag_spec
  ))

  lc_iam_instance_profile = lookup(var.lt_iam_instance_profile, "name", "") != "" ? lookup(var.lt_iam_instance_profile, "name", "") : lookup(var.lt_iam_instance_profile, "arn", "") != "" ? lookup(var.lt_iam_instance_profile, "arn", "") : null

  lc_ebs_block_devices = [for bd in var.lt_block_device_mappings : {
    device_name           = lookup(bd, "device_name", null),
    no_device             = lookup(bd, "no_device", null),
    delete_on_termination = lookup(lookup(bd, "ebs", {}), "delete_on_termination", null),
    encrypted             = lookup(lookup(bd, "ebs", {}), "encrypted", null),
    iops                  = lookup(lookup(bd, "ebs", {}), "iops", null),
    snapshot_id           = lookup(lookup(bd, "ebs", {}), "snapshot_id", null),
    volume_size           = lookup(lookup(bd, "ebs", {}), "volume_size", null),
    volume_type           = lookup(lookup(bd, "ebs", {}), "volume_type", null),
  } if length(lookup(bd, "ebs", {})) > 0]

  lc_ephemeral_block_devices = [for bd in var.lt_block_device_mappings : {
    device_name  = lookup(bd, "device_name", null),
    virtual_name = lookup(bd, "virtual_name", null),
  } if length(lookup(bd, "ebs", {})) == 0]

  asg_instances_distribution = lookup(var.asg_mixed_instances_policy, "instances_distribution", {})

  asg_launch_template = var.lc_use ? [{}] : [{
    id      = var.asg_launch_template_id != "" ? var.asg_launch_template_id : null,
    name    = var.asg_launch_template_id != "" ? null : var.asg_launch_template_name != "" ? var.asg_launch_template_name : element(aws_launch_template.this.*.name, 0)
    version = var.asg_launch_template_version != "" ? var.asg_launch_template_version : var.asg_launch_template_id != "" || var.asg_launch_template_name != "" ? "$Default" : element(aws_launch_template.this.*.latest_version, 0)
  }]

  asg_tags = [for k, v in merge(var.tags, var.asg_tags) : { key = k, value = v, propagate_at_launch = var.asg_tags_propagate_at_launch }]
}

data "aws_ami" "this" {
  count  = length(keys(var.lt_root_block_device)) > 0 && var.lc_use == false ? 1 : 0
  owners = var.lt_image_owners
  filter {
    name   = "image-id"
    values = [var.lt_image_id]
  }
}

data "template_file" "user_data" {
  template = var.lt_user_data
  vars     = var.lt_user_data_variables
}

data "aws_ec2_instance_type" "this" {
  count = var.lt_ebs_optimized_auto ? length(local.instance_types) : 0

  instance_type = local.instance_types[count.index]
}

#################
# Launch Template
#################

resource "aws_launch_template" "this" {
  count = var.lc_use ? 0 : 1

  name                    = var.lt_name_prefix != "" ? null : var.lt_name != "" ? var.lt_name : var.name
  name_prefix             = var.lt_name_prefix != "" ? var.lt_name_prefix : null
  description             = var.lt_description
  default_version         = var.lt_default_version != -1 ? var.lt_default_version : null
  update_default_version  = var.lt_default_version == -1 ? var.lt_update_default_version : null
  disable_api_termination = var.lt_disable_api_termination
  ebs_optimized           = local.lt_ebs_optimized
  image_id                = var.lt_image_id

  instance_initiated_shutdown_behavior = var.lt_instance_initiated_shutdown_behavior != "" ? var.lt_instance_initiated_shutdown_behavior : null

  instance_type          = var.lt_instance_type
  kernel_id              = var.lt_kernel_id != "" ? var.lt_kernel_id : null
  key_name               = var.lt_key_name
  ram_disk_id            = var.lt_ram_disk_id != "" ? var.lt_ram_disk_id : null
  vpc_security_group_ids = length(var.lt_network_interfaces) == 0 && var.lt_associate_public_ip_address == false ? var.lt_vpc_security_group_ids : null
  user_data              = var.lt_user_data_base64 != "" ? var.lt_user_data_base64 : var.lt_user_data != "" ? base64encode(data.template_file.user_data.rendered) : null

  dynamic "block_device_mappings" {
    for_each = local.lt_block_device_mappings
    content {
      device_name  = lookup(block_device_mappings.value, "device_name", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      dynamic "ebs" {
        for_each = length(keys(lookup(block_device_mappings.value, "ebs", {}))) > 0 ? [lookup(block_device_mappings.value, "ebs", {})] : []
        content {
          delete_on_termination = contains(keys(ebs.value), "delete_on_termination") ? ebs.value["delete_on_termination"] : true
          encrypted             = contains(keys(ebs.value), "encrypted") ? ebs.value["encrypted"] : false
          iops                  = lookup(ebs.value, "iops", null)
          kms_key_id            = lookup(ebs.value, "kms_key_id", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }

  dynamic "block_device_mappings" {
    for_each = local.lt_root_block_device
    content {
      device_name  = lookup(block_device_mappings.value, "device_name", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      dynamic "ebs" {
        for_each = length(keys(lookup(block_device_mappings.value, "ebs", {}))) > 0 ? [lookup(block_device_mappings.value, "ebs", {})] : []
        content {
          delete_on_termination = contains(keys(ebs.value), "delete_on_termination") ? ebs.value["delete_on_termination"] : true
          encrypted             = contains(keys(ebs.value), "encrypted") ? ebs.value["encrypted"] : false
          iops                  = lookup(ebs.value, "iops", null)
          kms_key_id            = lookup(ebs.value, "kms_key_id", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = length(keys(var.lt_capacity_reservation_specification)) > 0 ? [var.lt_capacity_reservation_specification] : []
    content {
      capacity_reservation_preference = lookup(capacity_reservation_specification.value, "capacity_reservation_preference", null)

      dynamic "capacity_reservation_target" {
        for_each = contains(keys(capacity_reservation_specification.value), "capacity_reservation_target") ? [lookup(capacity_reservation_specification.value, "capacity_reservation_target", {})] : []
        content {
          capacity_reservation_id = lookup(capacity_reservation_target.value, "capacity_reservation_id", null)
        }
      }
    }
  }

  dynamic "cpu_options" {
    for_each = length(keys(var.lt_cpu_options)) > 0 ? [var.lt_cpu_options] : []
    content {
      core_count       = lookup(cpu_options.value, "core_count", null)
      threads_per_core = lookup(cpu_options.value, "threads_per_core", null)
    }
  }

  dynamic "credit_specification" {
    for_each = length(keys(var.lt_credit_specification)) > 0 ? [var.lt_credit_specification] : []
    content {
      cpu_credits = lookup(credit_specification.value, "cpu_credits", null)
    }
  }

  dynamic "elastic_gpu_specifications" {
    for_each = length(keys(var.lt_elastic_gpu_specifications)) > 0 ? [var.lt_elastic_gpu_specifications] : []
    content {
      type = lookup(elastic_gpu_specifications.value, "type", null)
    }
  }

  dynamic "elastic_inference_accelerator" {
    for_each = length(keys(var.lt_elastic_inference_accelerator)) > 0 ? [var.lt_elastic_inference_accelerator] : []
    content {
      type = lookup(elastic_inference_accelerator.value, "type", null)
    }
  }

  dynamic "iam_instance_profile" {
    for_each = length(keys(var.lt_iam_instance_profile)) > 0 ? [var.lt_iam_instance_profile] : []
    content {
      arn  = lookup(iam_instance_profile.value, "arn", null)
      name = lookup(iam_instance_profile.value, "name", null)
    }
  }

  dynamic "instance_market_options" {
    for_each = length(keys(var.lt_instance_market_options)) > 0 ? [var.lt_instance_market_options] : []
    content {
      market_type = lookup(instance_market_options.value, "market_type", null)
      dynamic "spot_options" {
        for_each = contains(keys(instance_market_options.value), "spot_options") ? [lookup(instance_market_options.value, "spot_options", {})] : []
        content {
          block_duration_minutes         = lookup(spot_options.value, "block_duration_minutes", null)
          instance_interruption_behavior = lookup(spot_options.value, "instance_interruption_behavior", null)
          max_price                      = lookup(spot_options.value, "max_price", null)
          spot_instance_type             = lookup(spot_options.value, "spot_instance_type", null)
          valid_until                    = lookup(spot_options.value, "valid_until", null)
        }
      }
    }
  }

  dynamic "license_specification" {
    for_each = length(keys(var.lt_license_specification)) > 0 ? [var.lt_license_specification] : []
    content {
      license_configuration_arn = lookup(license_specification.value, "license_configuration_arn", null)
    }
  }

  dynamic "metadata_options" {
    for_each = length(keys(var.lt_metadata_options)) > 0 ? [var.lt_metadata_options] : []
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", null)
      http_tokens                 = lookup(metadata_options.value, "http_tokens", null)
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", null)
    }
  }

  dynamic "monitoring" {
    for_each = length(keys(var.lt_monitoring)) > 0 ? [var.lt_monitoring] : []
    content {
      enabled = lookup(monitoring.value, "enabled", null)
    }
  }

  dynamic "network_interfaces" {
    for_each = local.lt_network_interfaces
    content {
      associate_public_ip_address = lookup(network_interfaces.value, "associate_public_ip_address", null)
      delete_on_termination       = lookup(network_interfaces.value, "delete_on_termination", null)
      description                 = lookup(network_interfaces.value, "description", null)
      device_index                = lookup(network_interfaces.value, "device_index", null)
      ipv4_address_count          = lookup(network_interfaces.value, "ipv4_address_count", null)
      ipv4_addresses              = compact(split(",", lookup(network_interfaces.value, "ipv4_addresses", "")))
      ipv6_address_count          = lookup(network_interfaces.value, "ipv6_address_count", null)
      ipv6_addresses              = compact(split(",", lookup(network_interfaces.value, "ipv6_addresses", "")))
      network_interface_id        = lookup(network_interfaces.value, "network_interface_id", null)
      private_ip_address          = lookup(network_interfaces.value, "private_ip_address", null)
      security_groups             = compact(split(",", lookup(network_interfaces.value, "security_groups", "")))
      subnet_id                   = lookup(network_interfaces.value, "subnet_id", null)
    }
  }

  dynamic "placement" {
    for_each = length(keys(var.lt_placement)) > 0 ? [var.lt_placement] : []
    content {
      affinity          = lookup(placement.value, "affinity", null)
      availability_zone = lookup(placement.value, "availability_zone", null)
      group_name        = lookup(placement.value, "group_name", null)
      host_id           = lookup(placement.value, "host_id", null)
      spread_domain     = lookup(placement.value, "spread_domain", null)
      tenancy           = lookup(placement.value, "tenancy", null)
      partition_number  = lookup(placement.value, "partition_number", null)
    }
  }

  dynamic "tag_specifications" {
    for_each = local.lt_tag_specifications
    content {
      resource_type = tag_specifications.value["resource_type"]
      tags          = tag_specifications.value["tags"]
    }
  }

  dynamic "hibernation_options" {
    for_each = length(keys(var.lt_hibernation_options)) > 0 ? [var.lt_hibernation_options] : []
    content {
      configured = lookup(hibernation_options.value, "configured", null)
    }
  }

  tags = merge(
    var.tags,
    var.lt_tags
  )
}

######################
# Launch configuration
######################

resource "aws_launch_configuration" "this" {
  count = var.lc_use ? 1 : 0

  name        = var.lc_name != "" ? var.lc_name : null
  name_prefix = var.lc_name != "" ? null : var.lc_name_prefix != "" ? var.lc_name_prefix : "${var.name}-"

  image_id                    = var.lt_image_id
  instance_type               = var.lt_instance_type
  iam_instance_profile        = local.lc_iam_instance_profile
  key_name                    = var.lt_key_name
  security_groups             = var.lt_vpc_security_group_ids
  associate_public_ip_address = var.lt_associate_public_ip_address
  user_data                   = var.lt_user_data != "" ? data.template_file.user_data.rendered : null
  user_data_base64            = var.lt_user_data_base64 != "" ? var.lt_user_data_base64 : null
  enable_monitoring           = lookup(var.lt_monitoring, "enabled", null)
  ebs_optimized               = local.lt_ebs_optimized
  spot_price                  = lookup(lookup(var.lt_instance_market_options, "spot_options", {}), "max_price", null)
  placement_tenancy           = lookup(var.lt_placement, "tenancy", null)

  dynamic "root_block_device" {
    for_each = length(keys(var.lt_root_block_device)) > 0 ? [var.lt_root_block_device] : []
    content {
      delete_on_termination = contains(keys(root_block_device.value), "delete_on_termination") ? root_block_device.value["delete_on_termination"] : true
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      encrypted             = contains(keys(root_block_device.value), "encrypted") ? root_block_device.value["encrypted"] : false
    }
  }

  dynamic "ebs_block_device" {
    for_each = local.lc_ebs_block_devices
    content {
      device_name           = ebs_block_device.value["device_name"]
      delete_on_termination = contains(keys(ebs_block_device.value), "delete_on_termination") ? ebs_block_device.value["delete_on_termination"] : true
      encrypted             = contains(keys(ebs_block_device.value), "encrypted") ? ebs_block_device.value["encrypted"] : false
      iops                  = lookup(ebs_block_device.value, "iops", null)
      no_device             = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = local.lc_ephemeral_block_devices
    content {
      device_name  = ephemeral_block_device.value["device_name"]
      virtual_name = lookup(ephemeral_block_device.value, "virtual_name", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

###################
# AutoScaling group
###################

resource "aws_autoscaling_group" "this" {
  name                      = var.asg_name_prefix != "" ? null : var.asg_name != "" ? var.asg_name : var.name
  name_prefix               = var.asg_name_prefix != "" ? var.asg_name_prefix : null
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  default_cooldown          = var.asg_default_cooldown != -1 ? var.asg_default_cooldown : null
  launch_configuration      = var.lc_use ? var.asg_launch_configuration != "" ? var.asg_launch_configuration : element(aws_launch_configuration.this.*.name, 0) : null
  health_check_grace_period = var.asg_health_check_grace_period != -1 ? var.asg_health_check_grace_period : null
  health_check_type         = var.asg_health_check_type != "" ? var.asg_health_check_type : null
  desired_capacity          = var.asg_desired_capacity != -1 ? var.asg_desired_capacity : null
  force_delete              = var.asg_force_delete
  load_balancers            = length(var.asg_load_balancers) > 0 ? var.asg_load_balancers : null
  vpc_zone_identifier       = var.asg_subnet_ids
  target_group_arns         = length(var.asg_target_group_arns) > 0 ? var.asg_target_group_arns : null
  termination_policies      = length(var.asg_termination_policies) > 0 ? var.asg_termination_policies : null
  suspended_processes       = length(var.asg_suspended_processes) > 0 ? var.asg_suspended_processes : null
  placement_group           = var.asg_placement_group != "" ? var.asg_placement_group : null
  metrics_granularity       = var.asg_metrics_granularity != "" ? var.asg_metrics_granularity : null
  enabled_metrics           = length(var.asg_enabled_metrics) > 0 ? var.asg_enabled_metrics : null
  wait_for_capacity_timeout = var.asg_wait_for_capacity_timeout != "" ? var.asg_wait_for_capacity_timeout : null
  min_elb_capacity          = var.asg_min_elb_capacity != -1 ? var.asg_min_elb_capacity : null
  wait_for_elb_capacity     = var.asg_wait_for_elb_capacity != -1 ? var.asg_wait_for_elb_capacity : null
  protect_from_scale_in     = var.asg_protect_from_scale_in
  service_linked_role_arn   = var.asg_service_linked_role_arn != "" ? var.asg_service_linked_role_arn : null
  max_instance_lifetime     = var.asg_max_instance_lifetime != -1 ? var.asg_max_instance_lifetime : null

  dynamic "launch_template" {
    for_each = var.lc_use == false && length(keys(var.asg_mixed_instances_policy)) == 0 ? [local.asg_launch_template] : []
    content {
      id      = lookup(launch_template.value, "id", null)
      name    = lookup(launch_template.value, "name", null)
      version = lookup(launch_template.value, "version", null)
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.lc_use == false && length(keys(var.asg_mixed_instances_policy)) > 0 ? [var.asg_mixed_instances_policy] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id   = lookup(local.asg_launch_template[0], "id", null)
          launch_template_name = lookup(local.asg_launch_template[0], "name", null)
          version              = lookup(local.asg_launch_template[0], "version", null)
        }

        dynamic "override" {
          for_each = lookup(lookup(var.asg_mixed_instances_policy, "launch_template", {}), "override", [])
          content {
            instance_type     = lookup(override.value, "instance_type", null)
            weighted_capacity = lookup(override.value, "weighted_capacity", null)
          }
        }
      }

      dynamic "instances_distribution" {
        for_each = length(keys(lookup(var.asg_mixed_instances_policy, "instances_distribution", {}))) > 0 ? [lookup(var.asg_mixed_instances_policy, "instances_distribution", {})] : []
        content {
          on_demand_allocation_strategy            = lookup(instances_distribution.value, "on_demand_allocation_strategy", null)
          on_demand_base_capacity                  = lookup(instances_distribution.value, "on_demand_base_capacity", null)
          on_demand_percentage_above_base_capacity = lookup(instances_distribution.value, "on_demand_percentage_above_base_capacity", 100)
          spot_allocation_strategy                 = lookup(instances_distribution.value, "spot_allocation_strategy", null)
          spot_instance_pools                      = lookup(instances_distribution.value, "spot_instance_pools", null)
          spot_max_price                           = lookup(instances_distribution.value, "max_price", null)
        }
      }
    }
  }

  dynamic "initial_lifecycle_hook" {
    for_each = var.initial_lifecycle_hooks
    content {
      name                    = lookup(initial_lifecycle_hook.value, "name", null)
      default_result          = lookup(initial_lifecycle_hook.value, "default_result", null)
      heartbeat_timeout       = lookup(initial_lifecycle_hook.value, "heartbeat_timeout", null)
      lifecycle_transition    = lookup(initial_lifecycle_hook.value, "lifecycle_transition", null)
      notification_metadata   = lookup(initial_lifecycle_hook.value, "notification_metadata", null)
      notification_target_arn = lookup(initial_lifecycle_hook.value, "notification_target_arn", null)
      role_arn                = lookup(initial_lifecycle_hook.value, "role_arn", null)
    }
  }

  dynamic "tag" {
    for_each = local.asg_tags
    content {
      key                 = tag.value["key"]
      value               = tag.value["value"]
      propagate_at_launch = tag.value["propagate_at_launch"]
    }
  }
}
