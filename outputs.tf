output "launch_configuration" {
  description = "Launch configuration properties"
  value       = concat(aws_launch_configuration.this, [{}])[0]
}

output "launch_template" {
  description = "Launch template properties"
  value       = concat(aws_launch_template.this, [{}])[0]
}

output "autoscaling_group" {
  description = "AutoScaling Group properties"
  value       = { for k, v in aws_autoscaling_group.this : k => v if contains(["tags"], k) == false }
}
