provider "aws" {
  region = "ap-south-1"
}

## Autoscaling Launch Configuration ##

resource "aws_launch_configuration" "as_conf" {
  name            = "terraform-lc"
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
  name                 = "terraform-asg"
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

## Simple Scale-Out policy ##

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "terraform-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "SimpleScaling"
}

## Simple Scale-In policy ##

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "terraform-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "SimpleScaling"
}

## CloudWatch Alarm for High CPUUtilization ##

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "terraform-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors high cpu utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}


## CloudWatch Alarm for Low CPUUtilization ##

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "terraform-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "This metric monitors low cpu utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}