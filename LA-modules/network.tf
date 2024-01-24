provider "aws" {
      region     = "${var.region}"
      #access_key = "${var.access_key}"
      #secret_key = "${var.secret_key}"
}

# VPC resources: This will create 1 VPC with 4 Subnets, 1 Internet Gateway, 4 Route Tables. 
resource "aws_vpc" "VPC-LA" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "VPC-LA"
  }
}

resource "aws_security_group" "instances" {
  #name   = "HTTP and SSH"
  vpc_id = aws_vpc.VPC-LA.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
/*
resource "aws_security_group_rule" "allow_http_inbound" {
  #vpc_id = aws_vpc.VPC-LA.id
  type              = "ingress"
  security_group_id = aws_security_group.instances.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
*/

resource "aws_internet_gateway" "IG-LA" {
  vpc_id = aws_vpc.VPC-LA.id
  tags = {
    Name = "IG-LA"
  }
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.VPC-LA.id
}

resource "aws_route" "private" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  #nat_gateway_id         = aws_nat_gateway.default[count.index].id
  gateway_id             = aws_internet_gateway.IG-LA.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.VPC-LA.id
  
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IG-LA.id
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id            = aws_vpc.VPC-LA.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]
    tags = {
    Name = "Private" 
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.VPC-LA.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public"
}
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


/*# NAT resources: This will create 2 NAT gateways in 2 Public Subnets for 2 different Private Subnets.

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)
  #vpc = true
}

resource "aws_nat_gateway" "default" {
  depends_on = ["aws_internet_gateway.default"]

  count = length(var.public_subnet_cidr_blocks)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}*/