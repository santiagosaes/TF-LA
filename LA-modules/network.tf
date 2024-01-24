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

resource "aws_internet_gateway" "IG-LA" {
  vpc_id = aws_vpc.VPC-LA.id
  tags = {
    Name = "IG-LA"
  }
}

resource "aws_security_group" "alb" {
  name   = "SG ALB"
  vpc_id = aws_vpc.VPC-LA.id
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "instances" {
  name   = "SG Instances"
  vpc_id = aws_vpc.VPC-LA.id

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
#TABLAS DE ENRUTAMIENTO
resource "aws_route_table" "private" {
  #count = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.VPC-LA.id
}

resource "aws_route" "private" {
  #count = length(var.private_subnet_cidr_blocks)
  #route_table_id         = aws_route_table.private[count.index].id
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  #nat_gateway_id         = aws_nat_gateway.default[count.index].id
  #REEMPLAZAR EL GATEWAY POR UN NAT O POR UNA EC2.
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

#CREACION DE LAS SUBREDES PRIVADAS
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.VPC-LA.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]
    tags = {
    Name = "Private" 
  }
}

#CREACION DE LAS SUBREDES PUBLICAS
resource "aws_subnet" "public" {
  #name  = "public "
  count = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.VPC-LA.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public"
}
}

#ASOCIACION DE LAS SUBREDES A LA TABLA DE ENRUTAMIENTO
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  #route_table_id = aws_route_table.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#CREACION DEL BALANCEADOR DE CARGA
resource "aws_lb" "load_balancer" {
  name               = "${var.app_name}-${var.environment_name}-web-app-lb"
  load_balancer_type = "application"
  count = length(var.private_subnet_cidr_blocks)
  subnets            = [aws_subnet.private[0].id,aws_subnet.private[1].id]
  security_groups    = [aws_security_group.alb.id]
 
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port = 80
  protocol = "HTTP"
  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

#CONFIGURACION DEL TARGET GROUP
resource "aws_lb_target_group" "instances" {
  name     = "${var.app_name}-${var.environment_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.VPC-LA.id
  #aws_vpc.VPC-LA.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "instance_1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "instance_2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.instance_2.id
  port             = 8080
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
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