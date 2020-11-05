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
