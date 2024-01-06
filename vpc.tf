resource "aws_vpc" "vpc" {
  cidr_block       = var.main_vpc_cidr
  instance_tenancy = "default"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnets_cidr[0]
  availability_zone = "ca-central-1d"
  tags = {
    Name = "java-ms-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnets_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnets_a_cidr[0]
  availability_zone = "ca-central-1a"
  tags = {
    Name = "java-ms-public-subnet-2"
  }
}

resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnets_cidr[0]
  availability_zone = "ca-central-1d"
  tags = {
    Name = "java-ms-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnets_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnets_a_cidr[0]
  availability_zone = "ca-central-1a"
  tags = {
    Name = "java-ms-private-subnet-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnets.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_association" {
  subnet_id      = aws_subnet.private_subnets.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "public_rt_association_a" {
  subnet_id      = aws_subnet.public_subnets_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_association_a" {
  subnet_id      = aws_subnet.private_subnets_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_eip" "nat_e_ip" {
  vpc = true
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_e_ip.id
  subnet_id     = aws_subnet.public_subnets.id
}

resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "java-ms-service-sg"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 8101
    to_port     = 8101
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "java-ms-sg"
  }
}
