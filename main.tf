locals {

  lt_iam_instance_profile = var.iam_instance_profile != "" ? [var.iam_instance_profile] : []
  lt_root_block_device = length(keys(var.root_block_device)) == 0 ? [] : [{
    device_name  = data.aws_ami.this.root_device_name,
    virtual_name = lookup(var.root_block_device, "virtual_name", null),
    no_device    = lookup(var.root_block_device, "no_device", null),
    ebs = data.aws_ami.this.root_device_type == "instance-store" ? {} : {
      delete_on_termination = lookup(var.root_block_device, "delete_on_termination", null),
      encrypted             = lookup(var.root_block_device, "encrypted", null),
      iops                  = lookup(var.root_block_device, "iops", null),
      kms_key_id            = lookup(var.root_block_device, "volume_type", null),
      snapshot_id           = lookup(var.root_block_device, "snapshot_id", null),
      volume_size           = lookup(var.root_block_device, "volume_size", null),
      volume_type           = lookup(var.root_block_device, "volume_type", null),
    }
  }]
  lt_ephemeral_block_devices = [
    for device in var.ephemeral_block_devices : {
      device_name  = device["device_name"],
      virtual_name = lookup(device, "virtual_name", null),
      no_device    = lookup(var.root_block_device, "no_device", null),
      ebs          = {}
    }
  ]
  lt_ebs_block_devices = [
    for device in var.ebs_block_devices : {
      device_name = device["device_name"],
      no_device   = lookup(device, "no_device", null),
      ebs = {
        delete_on_termination = lookup(device, "delete_on_termination", null),
        encrypted             = lookup(device, "encrypted", null),
        iops                  = lookup(device, "iops", null),
        kms_key_id            = lookup(device, "volume_type", null),
        snapshot_id           = lookup(device, "snapshot_id", null),
        volume_size           = lookup(device, "volume_size", null),
        volume_type           = lookup(device, "volume_type", null),
      }
    }
  ]
  lt_block_device_mappings = concat(local.lt_root_block_device, local.lt_ebs_block_devices, local.lt_ephemeral_block_devices)
  lt_spot_options          = length(keys(var.spot_options)) > 0 ? [var.spot_options] : []
  lt_network_interfaces = concat(var.network_interfaces, length(var.network_interfaces) > 0 ? [] : [{
    associate_public_ip_address = var.associate_public_ip_address,
    srcurity_groups             = var.security_group_ids,
    delete_on_termination       = true,
    description                 = "Default network interface"
  }])

  lt_instance_tag_spec = length(keys(var.tags)) >= 0 ? [
    {
      resource_type = "instance",
      tags          = var.tags
    },
    {
      resource_type = "volume",
      tags          = var.tags
    }
  ] : []
  lt_spot_request_tag_spec = length(keys(var.tags)) > 0 && length(keys(var.spot_options)) > 0 && lookup(var.spot_options, "on_demand_percentage_above_base_capacity", 100) == 0 && lookup(var.spot_options, "on_demand_base_capacity", 100) == 0 ? [{
    resource_type = "spot-instances-request",
    tags          = var.tags
  }] : []
  lt_gpu_tag_spec = length(keys(var.tags)) > 0 && length(keys(var.elastic_gpu_specifications)) > 0 ? [{
    resource_type = "elastic-gpu",
    tags          = var.tags
  }] : []
  lt_tag_specifications = concat(var.tag_specifications, length(var.tag_specifications) > 0 ? [] : concat(
    local.lt_instance_tag_spec,
    local.lt_spot_request_tag_spec,
    local.lt_gpu_tag_spec
  ))

  lc_spot_price        = length(keys(var.spot_options)) > 0 ? lookup(var.spot_options, "max_price", "") : ""
  lc_placement_tenancy = length(keys(var.placement)) > 0 ? lookup(var.placement, "tenancy", "default") : ""

  asg_tags = [for k, v in var.tags : { key = k, value = v, propagate_at_launch = var.use_launch_configuration }]
}

data "aws_ami" "this" {
  owners = var.image_owners
  filter {
    name   = "image-id"
    values = [var.image_id]
  }
}

data "template_file" "user_data" {
  template = var.user_data
  vars     = var.user_data_variables
}

######################
# Launch configuration
######################

resource "aws_launch_configuration" "this" {
  count = var.use_launch_configuration ? 1 : 0

  name_prefix = "${var.name}-"

  image_id             = var.image_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null
  user_data_base64     = var.user_data != "" ? base64encode(data.template_file.user_data.rendered) : null
  enable_monitoring    = var.enable_monitoring

  security_groups             = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip_address

  spot_price        = local.lc_spot_price
  placement_tenancy = local.lc_placement_tenancy
  ebs_optimized     = var.ebs_optimized

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name           = ebs_block_device.value.device_name
      encrypted             = lookup(ebs_block_device.value, "encrypted", null)
      iops                  = lookup(ebs_block_device.value, "iops", null)
      no_device             = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id           = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size           = lookup(ebs_block_device.value, "volume_size", null)
      volume_type           = lookup(ebs_block_device.value, "volume_type", null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_devices
    content {
      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
    }
  }

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops                  = lookup(root_block_device.value, "iops", null)
      volume_size           = lookup(root_block_device.value, "volume_size", null)
      volume_type           = lookup(root_block_device.value, "volume_type", null)
      encrypted             = lookup(root_block_device.value, "encrypted", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

#################
# Launch Template
#################

resource "aws_launch_template" "this" {
  count = var.use_launch_configuration ? 0 : 1


  name                   = var.name
  description            = var.launch_template_description
  update_default_version = true

  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data != "" ? base64encode(data.template_file.user_data.rendered) : null
  ebs_optimized = var.ebs_optimized

  dynamic "iam_instance_profile" {
    for_each = local.lt_iam_instance_profile
    content {
      name = iam_instance_profile.value
    }
  }

  dynamic "monitoring" {
    for_each = [var.enable_monitoring]
    content {
      enabled = monitoring.value
    }
  }

  dynamic "placement" {
    for_each = length(keys(var.placement)) > 0 ? [var.placement] : []
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

  dynamic "instance_market_options" {
    for_each = var.spot_options
    content {
      market_type = "spot"
      spot_options {
        block_duration_minutes         = lookup(instance_market_options.value, "block_duration_minutes", null)
        instance_interruption_behavior = lookup(instance_market_options.value, "instance_interruption_behavior", null)
        max_price                      = lookup(instance_market_options.value, "max_price", null)
        spot_instance_type             = lookup(instance_market_options.value, "spot_instance_type", null)
        valid_until                    = lookup(instance_market_options.value, "valid_until", null)
      }
    }
  }

  dynamic "block_device_mappings" {
    for_each = local.lt_block_device_mappings
    content {
      device_name  = block_device_mappings.value["device_name"]
      virtual_name = block_device_mappings.value["virtual_name"]
      no_device    = block_device_mappings.value["no_device"]
      dynamic "ebs" {
        for_each = length(keys(block_device_mappings.value["ebs"])) > 0 ? [block_device_mappings.value["ebs"]] : []
        content {
          delete_on_termination = ebs.value["delete_on_termination"]
          encrypted             = ebs.value["encrypted"]
          iops                  = ebs.value["iops"]
          kms_key_id            = ebs.value["volume_type"]
          snapshot_id           = ebs.value["snapshot_id"]
          volume_size           = ebs.value["volume_size"]
          volume_type           = ebs.value["volume_type"]
        }
      }
    }
  }

  dynamic "elastic_gpu_specifications" {
    for_each = length(keys(var.elastic_gpu_specifications)) > 0 ? [var.elastic_gpu_specifications] : []
    content {
      type = lookup(elastic_gpu_specifications, "type", null)
    }
  }

  dynamic "network_interfaces" {
    for_each = local.lt_network_interfaces
    content {
      associate_public_ip_address = lookup(network_interfaces.value, "associate_public_ip_address", null)
      delete_on_termination       = lookup(network_interfaces.value, "delete_on_termination", null)
      description                 = lookup(network_interfaces.value, "description", null)
      device_index                = lookup(network_interfaces.value, "device_index", null)
      ipv6_addresses              = lookup(network_interfaces.value, "ipv6_addresses", null)
      ipv6_address_count          = lookup(network_interfaces.value, "ipv6_address_count", null)
      network_interface_id        = lookup(network_interfaces.value, "network_interface_id", null)
      private_ip_address          = lookup(network_interfaces.value, "private_ip_address", null)
      ipv4_address_count          = lookup(network_interfaces.value, "ipv4_address_count", null)
      ipv4_addresses              = lookup(network_interfaces.value, "ipv4_addresses", null)
      security_groups             = lookup(network_interfaces.value, "security_groups", null)
      subnet_id                   = lookup(network_interfaces.value, "subnet_id", null)
    }
  }

  dynamic "tag_specifications" {
    for_each = local.lt_tag_specifications
    content {
      resource_type = tag_specifications.value["resource_type"]
      tags          = tag_specifications.value["tags"]
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = length(keys(var.capacity_reservation_specification)) > 0 ? [var.capacity_reservation_specification] : []
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
    for_each = length(keys(var.cpu_options)) > 0 ? [var.cpu_options] : []
    content {
      core_count       = lookup(cpu_options.value, "core_count", null)
      threads_per_core = lookup(cpu_options.value, "threads_per_core", null)
    }
  }

  dynamic "credit_specification" {
    for_each = length(keys(var.credit_specification)) > 0 ? [var.credit_specification] : []
    content {
      cpu_credits = lookup(credit_specification.value, "cpu_credits", null)
    }
  }

  dynamic "elastic_inference_accelerator" {
    for_each = length(keys(var.elastic_inference_accelerator)) > 0 ? [var.elastic_inference_accelerator] : []
    content {
      type = lookup(elastic_inference_accelerator.value, "type", null)
    }
  }

  dynamic "license_specification" {
    for_each = var.license_specification_arns
    content {
      license_configuration_arn = license_specification.value
    }
  }

  dynamic "metadata_options" {
    for_each = length(keys(var.metadata_options)) > 0 ? [var.metadata_options] : []
    content {
      http_endpoint               = lookup(metadata_options.value, "http_endpoint", null)
      http_tokens                 = lookup(metadata_options.value, "http_tokens", null)
      http_put_response_hop_limit = lookup(metadata_options.value, "http_put_response_hop_limit", null)
    }
  }

  dynamic "hibernation_options" {
    for_each = length(keys(var.hibernation_options)) > 0 ? [var.hibernation_options] : []
    content {
      configured = lookup(hibernation_options.value, "configured", null)
    }
  }

  tags = var.tags
}

###################
# AutoScaling group
###################

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  max_size                  = var.max_size
  min_size                  = var.min_size
  default_cooldown          = var.default_cooldown != -1 ? var.default_cooldown : null
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type != "" ? var.health_check_type : null
  force_delete              = var.force_delete
  termination_policies      = length(var.termination_policies) > 0 ? var.termination_policies : null
  suspended_processes       = length(var.suspended_processes) > 0 ? var.suspended_processes : null
  placement_group           = var.placement_group != "" ? var.placement_group : null
  metrics_granularity       = var.metrics_granularity != "" ? var.metrics_granularity : null
  enabled_metrics           = length(var.enabled_metrics) > 0 ? var.enabled_metrics : null
  wait_for_capacity_timeout = var.wait_for_capacity_timeout != "" ? var.wait_for_capacity_timeout : null
  min_elb_capacity          = var.min_elb_capacity != -1 ? var.min_elb_capacity : null
  wait_for_elb_capacity     = var.wait_for_elb_capacity != -1 ? var.wait_for_elb_capacity : null
  protect_from_scale_in     = var.protect_from_scale_in
  service_linked_role_arn   = var.service_linked_role_arn != "" ? var.service_linked_role_arn : null
  max_instance_lifetime     = var.max_instance_lifetime != -1 ? var.max_instance_lifetime : null

  launch_configuration = var.use_launch_configuration ? element(aws_launch_configuration.this.*.name, 0) : null
  vpc_zone_identifier  = var.subnet_ids

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

  dynamic "mixed_instances_policy" {
    for_each = var.use_launch_configuration ? [] : [true]
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = element(aws_launch_template.this.*.id, 0)
          version            = element(aws_launch_template.this.*.latest_version, 0)
        }

        dynamic "override" {
          for_each = var.override_instance_types
          content {
            instance_type     = override.value["instance_type"]
            weighted_capacity = lookup(override.value, "weighted_capacity", null)
          }
        }
      }

      instances_distribution {
        on_demand_allocation_strategy            = lookup(var.instances_distribution, "on_demand_allocation_strategy", null)
        on_demand_base_capacity                  = lookup(var.instances_distribution, "on_demand_base_capacity", null)
        on_demand_percentage_above_base_capacity = lookup(var.instances_distribution, "on_demand_percentage_above_base_capacity", 100)
        spot_allocation_strategy                 = lookup(var.instances_distribution, "spot_allocation_strategy", null)
        spot_instance_pools                      = lookup(var.instances_distribution, "spot_instance_pools", null)
        spot_max_price                           = lookup(var.spot_options, "max_price", null)
      }
    }
  }

  tags = local.asg_tags
}
