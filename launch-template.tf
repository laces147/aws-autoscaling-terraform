# -----------------------------
# Find Ubuntu 22.04 AMI
# -----------------------------

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}


# -----------------------------
# Launch Template
# -----------------------------

resource "aws_launch_template" "web" {
  name_prefix   = "autoscaling-web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update -y
    apt-get install -y apache2 stress

    systemctl enable apache2
    systemctl start apache2

    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
      <title>AWS Auto Scaling Project</title>
    </head>
    <body>
      <h1>It works!</h1>
      <h2>AWS Auto Scaling Project</h2>
      <p>Server created automatically by the Auto Scaling Group.</p>
      <p>Hostname: $(hostname)</p>
    </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "autoscaling-web-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}