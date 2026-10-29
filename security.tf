# -----------------------------
# ALB Security Group
# -----------------------------

resource "aws_security_group" "alb" {
  name        = "autoscaling-alb-sg"
  description = "Allow HTTP traffic to the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "autoscaling-alb-sg"
  }
}


# -----------------------------
# EC2 Security Group
# -----------------------------

resource "aws_security_group" "ec2" {
  name        = "autoscaling-ec2-sg"
  description = "Allow HTTP traffic from the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "autoscaling-ec2-sg"
  }
}