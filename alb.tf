# -----------------------------
# Application Load Balancer
# -----------------------------

resource "aws_lb" "web" {
  name               = "autoscaling-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "autoscaling-alb"
  }
}


# -----------------------------
# Target Group
# -----------------------------

resource "aws_lb_target_group" "web" {
  name     = "autoscaling-targets"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "autoscaling-target-group"
  }
}


# -----------------------------
# ALB Listener
# -----------------------------

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.web.arn
      }
    }
  }
}