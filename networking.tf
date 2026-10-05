# -----------------------------
# VPC
# -----------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "autoscaling-vpc"
  }
}


# -----------------------------
# Public Subnet A
# -----------------------------

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "autoscaling-public-a"
  }
}


# -----------------------------
# Public Subnet B
# -----------------------------

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "autoscaling-public-b"
  }
}


# -----------------------------
# Private Subnet A
# -----------------------------

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "autoscaling-private-a"
  }
}


# -----------------------------
# Private Subnet B
# -----------------------------

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "autoscaling-private-b"
  }
}


# -----------------------------
# Internet Gateway
# -----------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "autoscaling-igw"
  }
}


# -----------------------------
# Elastic IP for NAT Gateway
# -----------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "autoscaling-nat-eip"
  }
}


# -----------------------------
# NAT Gateway
# -----------------------------

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id

  depends_on = [
    aws_internet_gateway.main
  ]

  tags = {
    Name = "autoscaling-nat"
  }
}


# -----------------------------
# Public Route Table
# -----------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "autoscaling-public-rt"
  }
}


# -----------------------------
# Public Route Table Associations
# -----------------------------

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


# -----------------------------
# Private Route Table
# -----------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "autoscaling-private-rt"
  }
}


# -----------------------------
# Private Route Table Associations
# -----------------------------

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}