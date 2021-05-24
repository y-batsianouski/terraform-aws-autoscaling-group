# terraform-aws-autoscaling-group module changelog

## 0.1.0

- Initial version

## 0.1.1

- Add posibility to pass load_balancers and target_group_arns to ASG
- Add outputs

## 0.2.0

- Update variables naming
- Use Launch Template as base configuration resource for AutoScaling group
- Add possibility to pass pre-created Launch Template or Launch Configuration
- Add possibility to override name for Launch Template or Launch Configuration
- Add possibility to use name_prefix instead of name for Launch Template, Launch Configuration and AutoScaling group
- Add possibility to pass additional tags for Launch Template and AutoScaling group

## 0.2.1

- FIX root block device behaviour

## 0.2.2

- Set default values for delete_on_termination and encrypted arguments of EBS volume configurations

## 0.2.3

- FIX typo in kms_key_id for EBS configuration

## 0.3.0

- Add `asg_` prefix to `subnet_ids` and `initial_lifecycle_hooks` variables

## 0.3.1

- Add `aws_autoscaling_lifecycle_hook` resource support

## 0.3.2

- Update README.md

## 0.3.3

- FIX `initial_lyfecycle_hook` block in aws_autoscaling_group resource

## 0.3.4

- FIX typo in `aws_autoscaling_lyfecycle_hook` resource

## 0.3.5

- Fix EBS configuration
- Add Name tag to launch template
- FIX launch template block for autoscaling group
- Add support for scaling policies