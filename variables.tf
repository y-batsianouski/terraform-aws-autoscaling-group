##################
# Global Variables
##################

variable "name" {
  description = "Name for the created resources"
  type        = string
}

variable "tags" {
  description = "Map of tags to add to all created resources"
  type        = map(string)
  default     = {}
}

################################
# Launch Configuration variables
################################

variable "lc_use" {
  description = "Use Launch Configuration instead of Launch Template. All Launch Configuration variables will be automatically convertered to use with aws_launch_template resource"
  type        = bool
  default     = false
}

variable "lc_name" {
  description = "Define and use Launch Configuration name instead of name_prefix"
  type        = string
  default     = ""
}

variable "lc_name_prefix" {
  description = "Override name_prefix for Launch Configuration. var.name will be used by default"
  type        = string
  default     = ""
}

###########################
# Launch Template variables
###########################

variable "lt_name" {
  description = "Override Launch Template name. var.name will be used by default"
  type        = string
  default     = ""
}

variable "lt_name_prefix" {
  description = "Define and use name_prefix for Launch Template instead of name"
  type        = string
  default     = ""
}

variable "lt_description" {
  description = "Launch Template description"
  type        = string
  default     = ""
}

variable "lt_default_version" {
  description = "Specify default version for the Launch Template."
  type        = number
  default     = -1
}

variable "lt_update_default_version" {
  description = "Update default version of Launch Template each resource update. Not applicable if lt_default_version is set"
  type        = bool
  default     = true
}

variable "lt_disable_api_termination" {
  description = "If true, enables EC2 Instance termination protection"
  type        = bool
  default     = false
}

variable "lt_ebs_optimized" {
  description = "If true, launched EC2 instances will beEBS-optimized"
  type        = bool
  default     = false
}

variable "lt_ebs_optimized_auto" {
  description = "If true, this module automatically detected is ebs_optimized option can be enabled or not"
  type        = bool
  default     = false
}

variable "lt_image_id" {
  description = "AMI ID to use to launch EC2 instances"
  type        = string
}

variable "lt_image_owners" {
  description = "AMI ID owners to use in aws_ami data-source to know root block device name for root_block_device variable"
  type        = list(string)
  default = [
    "self",
    "amazon",
    "aws-marketplace",
    "microsoft"
  ]
}

variable "lt_instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance"
  type        = string
  default     = ""
}

variable "lt_instance_type" {
  description = "EC2 instance type to launch instances"
  type        = string
  default     = "t3.small"
}

variable "lt_kernel_id" {
  description = "The kernel ID"
  type        = string
  default     = ""
}

variable "lt_key_name" {
  description = "SSH key name to use with EC2 instances"
  type        = string
}

variable "lt_ram_disk_id" {
  description = "The ID of the RAM disk"
  type        = string
  default     = ""
}

variable "lt_vpc_security_group_ids" {
  description = "A list of security group IDs to associate with EC2 instances This variable is skipped if lt_network_interfaces variable is defined. Also used in Launch Configuration."
  type        = list(string)
  default     = []
}

variable "lt_associate_public_ip_address" {
  description = "Associate public ip address with an instance in a VPC. This variable is skipped if lt_network_interfaces variable is defined"
  type        = bool
  default     = false
}

variable "lt_user_data" {
  description = "Not base64 encoded user data. Can be terraform template to use in template_file data-source"
  type        = string
  default     = ""
}

variable "lt_user_data_variables" {
  description = "Map of variables to pass to user data template"
  type        = map(string)
  default     = {}
}

variable "lt_user_data_base64" {
  description = "base64 encoded user data"
  type        = string
  default     = ""
}

variable "lt_block_device_mappings" {
  description = "List of maps of block_device_mappings configuration blocks. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = any
  default     = []
}

variable "lt_root_block_device" {
  description = "Same syntax as for block_device_mappings but device_name for will be automatically filled using aws_ami data source so you don't need to care about it. Use lt_block_device_mappings variable if you don't want to use aws_ami data-source. This variable also required to configure root block device when using Launch Configuration (lc_use = true)"
  type        = any
  default     = {}
}

variable "lt_capacity_reservation_specification" {
  description = "capacity_reservation_specification block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(any)
  default     = {}
}

variable "lt_cpu_options" {
  description = "cpu_options block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_credit_specification" {
  description = "credit_specification block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_elastic_gpu_specifications" {
  description = "elastic_gpu_specifications block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_elastic_inference_accelerator" {
  description = "elastic_inference_accelerator block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_iam_instance_profile" {
  description = "The name of the IAM instance profile"
  type        = map(string)
  default     = {}
}

variable "lt_instance_market_options" {
  description = "instance_market_options block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = any
  default     = {}
}

variable "lt_license_specification" {
  description = "license_specification block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_metadata_options" {
  description = "metadata_options block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_monitoring" {
  description = "monitoring block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_network_interfaces" {
  description = "Define configuration for instance network interfaces. Applicable only for Launch Template"
  type        = list(map(string))
  default     = []
}

variable "lt_placement" {
  description = "placement block of Launch Template. Look at aws_launch_template resource documentation for all available configuration arguments"
  type        = map(string)
  default     = {}
}

variable "lt_tag_specifications" {
  description = "The tags to apply to the resources during launch. By default var.tags will be used. Applicable only for Launch Template"
  type = list(object({
    resource_type = string,
    tags          = map(string)
  }))
  # type    = list(map(any))
  default = []
}

variable "lt_hibernation_options" {
  description = "hibernation_options block of Launch Template"
  type        = map(string)
  default     = {}
}

variable "lt_tags" {
  description = "Add additional tags to Launch Template"
  type        = map(string)
  default     = {}
}

#############################
# AutoScaling Group variables
#############################

variable "asg_name" {
  description = "Override AutoScaling group name. By default var.name will be used"
  type        = string
  default     = ""
}

variable "asg_name_prefix" {
  description = "Define and use name_prefix instead of name for AutoScaling group"
  type        = string
  default     = ""
}

variable "asg_subnet_ids" {
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside"
  type        = list(string)
}

variable "asg_min_size" {
  description = "min size of AutoScaling group"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Max size of AutoScaling group"
  type        = number
  default     = 1
}

variable "asg_default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start."
  type        = number
  default     = -1
}

variable "asg_launch_configuration" {
  description = "Pass pre-existed Launch Configuration name to use with AutoScaling group. Launch Template or Launch Configuration will not be created if defined. Requires lc_use = true"
  type        = string
  default     = ""
}

variable "asg_launch_template_id" {
  description = "Pass pre-existed Launch Template ID to use with AutoScaling group. Launch Template or Launch Configuration will not be created if defined"
  type        = string
  default     = ""
}

variable "asg_launch_template_name" {
  description = "Pass pre-existed Launch Template name to use with AutoScaling group. Launch Template or Launch Configuration will not be created if defined"
  type        = string
  default     = ""
}

variable "asg_launch_template_version" {
  description = "Launch Template version. By default $Default used for external Launch Template and latest version for Launch Template managed by this module"
  type        = string
  default     = ""
}

variable "asg_health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health."
  type        = number
  default     = -1
}

variable "asg_health_check_type" {
  description = "\"EC2\" or \"ELB\". Controls how health checking is done."
  type        = string
  default     = ""
}

variable "asg_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  type        = number
  default     = -1
}

variable "asg_force_delete" {
  description = "Allows deleting the autoscaling group without waiting for all instances in the pool to terminate"
  type        = bool
  default     = false
}

variable "asg_load_balancers" {
  description = "A list of elastic load balancer names to add to the autoscaling group names. Only valid for classic load balancers. For ALBs, use target_group_arns instead."
  type        = list(string)
  default     = []
}

variable "asg_target_group_arns" {
  description = "A list of aws_alb_target_group ARNs, for use with Application or Network Load Balancing."
  type        = list(string)
  default     = []
}

variable "asg_termination_policies" {
  description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, OldestLaunchTemplate, AllocationStrategy, Default."
  type        = list(string)
  default     = []
}

variable "asg_suspended_processes" {
  description = "A list of processes to suspend for the AutoScaling Group. The allowed values are Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer. Note that if you suspend either the Launch or Terminate process types, it can prevent your autoscaling group from functioning properly"
  type        = list(string)
  default     = []
}

variable "asg_placement_group" {
  description = "The name of the placement group into which you'll launch your instances, if any"
  type        = string
  default     = ""
}

variable "asg_metrics_granularity" {
  description = "The granularity to associate with the metrics to collect. The only valid value is 1Minute. Default is 1Minute"
  type        = string
  default     = ""
}

variable "asg_enabled_metrics" {
  description = "A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances"
  type        = list(string)
  default     = []
}

variable "asg_wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out"
  type        = string
  default     = ""
}

variable "asg_min_elb_capacity" {
  description = "Setting this causes Terraform to wait for this number of instances from this autoscaling group to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes"
  type        = number
  default     = -1
}

variable "asg_wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances from this autoscaling group in all attached load balancers on both create and update operations"
  type        = number
  default     = -1
}

variable "asg_protect_from_scale_in" {
  description = "Allows setting instance protection. The autoscaling group will not select instances with this setting for termination during scale in events"
  type        = bool
  default     = false
}

variable "asg_service_linked_role_arn" {
  description = "The ARN of the service-linked role that the ASG will use to call other AWS services"
  type        = string
  default     = ""
}

variable "asg_max_instance_lifetime" {
  description = "The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 604800 and 31536000 seconds"
  type        = number
  default     = -1
}

variable "asg_mixed_instances_policy" {
  description = "mixed_instances_policy configuration block of AutoScaling group. Look aws_autoscaling_group resource documentation for all available configuration arguments. mixed_instances_policy.launch_template.launch_template_specification block will be filled automatically."
  type        = any
  default     = {}
}

variable "asg_initial_lifecycle_hooks" {
  description = "One or more Initial Lifecycle Hooks to attach to the autoscaling group before instances are launched"
  type        = list(map(string))
  default     = []
}

variable "asg_lifecycle_hooks" {
  description = "One or more Lifecycle Hooks to attach to the autoscaling group using aws_autoscaling_lifecycle_hook resource"
  type        = list(map(string))
  default     = []
}

variable "asg_scaling_policies" {
  description = "One or more scaling policies for autoscaling group"
  type        = any
  default     = []
}

variable "asg_tags_propagate_at_launch" {
  description = "Propagate AutoScaling group tags to the launched EC2 instances"
  type        = bool
  default     = true
}

variable "asg_tags" {
  description = "Add additional tags to the AutoScaling group"
  type        = map(string)
  default     = {}
}
