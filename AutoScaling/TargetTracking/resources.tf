provider "aws" {
  region = var.region
}

## Autoscaling Launch Configuration ##

resource "aws_launch_configuration" "as_conf" {
  name_prefix     = "terraform-lc-"
  image_id        = data.aws_ami.linux2_ami.image_id
  instance_type   = var.instance_type
  key_name        = var.ec2_key
  security_groups = var.security_group
  user_data       = <<EOF
               #!/bin/bash
               sudo yum update
               sudo yum install -y httpd
               sudo systemctl start httpd
               sudo systemctl enable httpd
               echo "<h1>Hello from Terraform</h1>" | sudo tee /var/www/html/index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

## Autoscaling Group ##

resource "aws_autoscaling_group" "asg" {
  name_prefix          = "terraform-asg-"
  availability_zones   = data.aws_availability_zones.available.names
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  launch_configuration = aws_launch_configuration.as_conf.id
  tag {
    key                 = "Name"
    value               = "terraform-servers"
    propagate_at_launch = true
  }
}

## Target Tracking Policy ##

resource "aws_autoscaling_policy" "target_track" {
  name                   = "terraform-target_track"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}
