##################
# Global Variables
##################

variable "name" {
  description = "Name for the created resources"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside"
  type        = list(string)
}

variable "tags" {
  description = "Map of tags to add to all created resources"
  type        = map(string)
  default     = {}
}

variable "use_launch_configuration" {
  description = "Use launch configuration instead of launch template"
  type        = bool
  default     = false
}

###############################################
# LaunchTempolate/LaunchConfiguration variables
###############################################

variable "launch_template_description" {
  description = "Launch Template description"
  type        = string
  default     = "Managed by terraform"
}

variable "image_id" {
  description = "AMI ID to use to launch EC2 instances"
  type        = string
}

variable "image_owners" {
  description = "AMI Id owners to use in data resource."
  type        = list(string)
  default = [
    "self",
    "amazon",
    "aws-marketplace",
    "microsoft"
  ]
}

variable "key_name" {
  description = "SSH key name to use with EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type to use in Launch Template or Launch Configuration"
  type        = string
  default     = "t3.small"
}

variable "iam_instance_profile" {
  description = "The name of the IAM instance profile"
  type        = string
  default     = ""
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the instance"
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Associate a public ip address with an instance in a VPC"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for EC2 instances"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data to provide when launching the instance. Can be terraform template to use in data.template_file"
  type        = string
  default     = ""
}
variable "user_data_variables" {
  description = "Map of variables to pass to user data template"
  type        = map(string)
  default     = {}
}

variable "root_block_device" {
  description = "Customize details about the root block device of the instance"
  type        = map(string)
  default     = {}
}

variable "ebs_block_devices" {
  description = "Additional EBS block devices to attach to the instance"
  type        = list(map(string))
  default     = []
}

variable "ephemeral_block_devices" {
  description = "Customize Ephemeral (also known as 'Instance Store') volumes on the instance"
  type        = list(map(string))
  default     = []
}

variable "ebs_optimized" {
  description = "Enable EBS optimized"
  type        = bool
  default     = false
}

variable "placement" {
  description = "The placement of the instance"
  type        = map(string)
  default     = {}
}

variable "spot_options" {
  description = "The options for Spot Instance. Spot instances will be automatically enabled if defined"
  type        = map(string)
  default     = {}
}

variable "elastic_gpu_specifications" {
  description = "The elastic GPU to attach to the instance. Applicable only for Launch Template"
  type        = map(string)
  default     = {}
}

variable "network_interfaces" {
  description = "Define configuration for instance network interfaces. Applicable only for Launch Template"
  type        = list(map(string))
  default     = []
}

variable "tag_specifications" {
  description = "The tags to apply to the resources during launch. By default var.tags will be used. Applicable only for Launch Template"
  type = list(object({
    resources_type = string,
    tags           = map(string)
  }))
  # type    = list(map(any))
  default = []
}

variable "capacity_reservation_specification" {
  description = "capacity_reservation_specification block of Launch Template"
  type        = map(any)
  default     = {}
}

variable "cpu_options" {
  description = "cpu_options block of Launch Template"
  type        = map(string)
  default     = {}
}

variable "license_specification_arns" {
  description = "List of license ARNs"
  type        = list(string)
  default     = []
}

variable "credit_specification" {
  description = "credit_specification block of Launch Template"
  type        = map(string)
  default     = {}
}

variable "elastic_inference_accelerator" {
  description = "elastic_inference_accelerator block of Launch Template"
  type        = map(string)
  default     = {}
}

variable "metadata_options" {
  description = "metadata_options block of Launch Template"
  type        = map(string)
  default     = {}
}

variable "hibernation_options" {
  description = "hibernation_options block of Launch Template"
  type        = map(string)
  default     = {}
}

#############################
# AutoScaling Group variables
#############################

variable "min_size" {
  description = "min size of autoscaling group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Max size of autoscaling group"
  type        = number
  default     = 1
}

variable "default_cooldown" {
  description = "The amount of time, in seconds, after a scaling activity completes before another scaling activity can start."
  type        = number
  default     = -1
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health."
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "\"EC2\" or \"ELB\". Controls how health checking is done."
  type        = string
  default     = ""
}

variable "force_delete" {
  description = "Allows deleting the autoscaling group without waiting for all instances in the pool to terminate"
  type        = bool
  default     = false
}

variable "termination_policies" {
  description = "A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, OldestLaunchTemplate, AllocationStrategy, Default."
  type        = list(string)
  default     = []
}

variable "suspended_processes" {
  description = "A list of processes to suspend for the AutoScaling Group. The allowed values are Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer. Note that if you suspend either the Launch or Terminate process types, it can prevent your autoscaling group from functioning properly"
  type        = list(string)
  default     = []
}

variable "placement_group" {
  description = "The name of the placement group into which you'll launch your instances, if any"
  type        = string
  default     = ""
}

variable "metrics_granularity" {
  description = "The granularity to associate with the metrics to collect. The only valid value is 1Minute. Default is 1Minute"
  type        = string
  default     = ""
}

variable "enabled_metrics" {
  description = "A list of metrics to collect. The allowed values are GroupDesiredCapacity, GroupInServiceCapacity, GroupPendingCapacity, GroupMinSize, GroupMaxSize, GroupInServiceInstances, GroupPendingInstances, GroupStandbyInstances, GroupStandbyCapacity, GroupTerminatingCapacity, GroupTerminatingInstances, GroupTotalCapacity, GroupTotalInstances"
  type        = list(string)
  default     = []
}

variable "wait_for_capacity_timeout" {
  description = "A maximum duration that Terraform should wait for ASG instances to be healthy before timing out"
  type        = string
  default     = ""
}

variable "min_elb_capacity" {
  description = "Setting this causes Terraform to wait for this number of instances from this autoscaling group to show up healthy in the ELB only on creation. Updates will not wait on ELB instance number changes"
  type        = number
  default     = -1
}

variable "wait_for_elb_capacity" {
  description = "Setting this will cause Terraform to wait for exactly this number of healthy instances from this autoscaling group in all attached load balancers on both create and update operations"
  type        = number
  default     = -1
}

variable "protect_from_scale_in" {
  description = "Allows setting instance protection. The autoscaling group will not select instances with this setting for termination during scale in events"
  type        = bool
  default     = false
}

variable "service_linked_role_arn" {
  description = "The ARN of the service-linked role that the ASG will use to call other AWS services"
  type        = string
  default     = ""
}

variable "max_instance_lifetime" {
  description = "The maximum amount of time, in seconds, that an instance can be in service, values must be either equal to 0 or between 604800 and 31536000 seconds"
  type        = number
  default     = -1
}

variable "instances_distribution" {
  description = "Instances distribution configuration for the autoscaling group. For the spot_max_price will be used value of spot_options.max_price"
  type        = map(string)
  default     = {}
}

variable "override_instance_types" {
  description = "List of instance types to override in mixed_instances_policy. Only applicable when using Launch Template [{ instance_type = \"\", weighted_capacity = \"\" }]"
  type        = list(map(string))
  default     = []
}

variable "initial_lifecycle_hooks" {
  description = "One or more Lifecycle Hooks to attach to the autoscaling group before instances are launched"
  type        = list(map(string))
  default     = []
}
