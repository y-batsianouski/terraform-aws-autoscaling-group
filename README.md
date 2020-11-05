# terraform-aws-autoscaling-group

Terraform module to create AWS AutoScaling group and accompanying resources

Requires:

- terraform: `>= 0.13.0, < 0.14.0`
- provider aws: `>= 2.68, < 4.0`

[terraform registry](https://registry.terraform.io/modules/y-batsianouski/autoscaling-group/aws)

## Resources

- (Optionally) Launch Configuration instead of Launch Template
- Launch Template
- AWS AutoScaling group

Also may be used pre-created Launch Configuration or Launch Template

Only VPC AutoScaling groups supported.

## Examples

### AutoScaling group with Launch Template and Spot Instances

```terraform
module "autoscaling-group" {
  source = "y-batsianouski/autoscaling-group/aws"

  name       = "asg-with-launch-template"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  lt_description                 = "Launch Template for example AutoScaling group"
  lt_ebs_optimized_auto          = true
  lt_image_id                    = "ami-080addb03c9a21ab9"
  lt_instance_type               = "m5.xlarge"
  lt_key_name                    = "id-rsa"
  lt_vpc_security_group_ids      = ["sg-12345678", "sg-87654321"]
  lt_associate_public_ip_address = true
  lt_user_data                   = <<-EOF
    #!/bin/bash
    export UPDATE=${update}
    export PACKAGE=${package}

    if [[ $UPDATE == "true" ]]; then
      yum update
    fi
    yum install -y $PACKAGE
  EOF
  lt_user_data_variables = {
    update  = "true"
    package = "python"
  }
  lt_block_device_mappings = [
    {
      device_name = "/dev/sdb"
      ebs = {
        delete_on_termination = true,
        volume_size           = 300,
        volume_type           = "gp2"
      }
    }
  ]
  lt_root_block_device = {
    ebs = {
      volume_size = 100
    }
  }
  lt_iam_instance_profile = {
    name = "example-iam-role"
  }
  lt_monitoring = {
    enabled = true
  }
  lt_instance_market_options = {
    market_type = "spot",
    spot_options = {
      max_price          = 0.001,
      spot_instance_type = "persistent"
    }
  }

  asg_min_size          = 1
  asg_max_size          = 10
  asg_health_check_type = "EC2"
  asg_load_balancers    = ["example-load-balancer"]
  asg_mixed_instances_policy = {
    launch_template = {
      override = [
        {
          instance_type = "m3.large"
        },
        {
          instance_type = "m4.large"
        },
        {
          instance_type = "m5.large"
        }
      ]
    },
    instances_distribution = {
      on_demand_base_capacity                  = 1,
      on_demand_percentage_above_base_capacity = 100,
      spot_allocation_strategy                 = "capacity-optimized",
      spot_max_price                           = 0.002
    }
  }
  asg_tags_propagate_at_launch = true

  tags = {
    tier = "example"
  }
}
```

### AutoScaling group with Launch Configuration and Spot Instances

```terraform
module "autoscaling-group" {
  source = "y-batsianouski/autoscaling-group/aws"

  name       = "asg-with-launch-configuration"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  lc_use = true

  lt_description                 = "Launch Template for example AutoScaling group"
  lt_ebs_optimized_auto          = true
  lt_image_id                    = "ami-080addb03c9a21ab9"
  lt_instance_type               = "m5.xlarge"
  lt_key_name                    = "id-rsa"
  lt_vpc_security_group_ids      = ["sg-12345678", "sg-87654321"]
  lt_associate_public_ip_address = true
  lt_user_data                   = <<-EOF
    #!/bin/bash
    export UPDATE=${update}
    export PACKAGE=${package}

    if [[ $UPDATE == "true" ]]; then
      yum update
    fi
    yum install -y $PACKAGE
  EOF
  lt_user_data_variables = {
    update  = "true"
    package = "python"
  }
  lt_block_device_mappings = [
    {
      device_name = "/dev/sdb"
      ebs = {
        delete_on_termination = true,
        volume_size           = 300,
        volume_type           = "gp2"
      }
    }
  ]
  lt_root_block_device = {
    ebs = {
      volume_size = 100
    }
  }
  lt_iam_instance_profile = {
    name = "example-iam-role"
  }
  lt_monitoring = {
    enabled = true
  }
  lt_instance_market_options = {
    spot_options = {
      max_price          = 0.001
    }
  }

  asg_min_size          = 1
  asg_max_size          = 10
  asg_health_check_type = "EC2"
  asg_load_balancers    = ["example-load-balancer"]
  asg_tags_propagate_at_launch = true

  tags = {
    tier = "example"
  }
}
```
