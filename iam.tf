# -----------------------------
# IAM Role for EC2
# -----------------------------

resource "aws_iam_role" "ec2_role" {
  name = "autoscaling-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "autoscaling-ec2-role"
  }
}


# -----------------------------
# SSM Managed Instance Core
# -----------------------------

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# -----------------------------
# CloudWatch Agent Server Policy
# -----------------------------

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# -----------------------------
# EC2 Instance Profile
# -----------------------------

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "autoscaling-ec2-profile"
  role = aws_iam_role.ec2_role.name
}