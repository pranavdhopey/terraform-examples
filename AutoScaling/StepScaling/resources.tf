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
  desired_capacity     = 0
  max_size             = 3
  min_size             = 0
  launch_configuration = aws_launch_configuration.as_conf.id
  tag {
    key                 = "Name"
    value               = "terraform-servers"
    propagate_at_launch = true
  }
}

## Step Scale-Out policy ##

resource "aws_autoscaling_policy" "step_scale_up" {
  name                   = "terraform-step-scaling_up"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "StepScaling"

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 10
  }
  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 10
    metric_interval_upper_bound = 20
  }
  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 20
    metric_interval_upper_bound = null
  }
}

## Step Scale-In policy ##

resource "aws_autoscaling_policy" "step_scale_down" {
  name                   = "terraform-step-scaling_down"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "StepScaling"

  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_lower_bound = -10
    metric_interval_upper_bound = 0
  }
  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_lower_bound = null
    metric_interval_upper_bound = -10
  }
}

## CloudWatch Alarm for High CPUUtilization ##

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "terraform-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors high cpu utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [aws_autoscaling_policy.step_scale_up.arn]
}

## CloudWatch Alarm for Low CPUUtilization ##

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "terraform-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors low cpu utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [aws_autoscaling_policy.step_scale_down.arn]
}
