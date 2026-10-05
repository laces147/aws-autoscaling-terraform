# -----------------------------
# Auto Scaling Group
# -----------------------------

resource "aws_autoscaling_group" "web" {
  name = "autoscaling-web-asg"

  min_size         = 1
  desired_capacity = 1
  max_size         = 6

  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "autoscaling-web-server"
    propagate_at_launch = true
  }
}


# -----------------------------
# Target Tracking Scaling Policy
# -----------------------------

resource "aws_autoscaling_policy" "cpu" {
  name                   = "autoscaling-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}