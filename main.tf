terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available_azs" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.title}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.title}-igw"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = aws_availability_zones.available_azs.names[0]

  tags = {
    Name = "${var.title}-public_subnet_1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = aws_availability_zones.available_azs.names[1]

  tags = {
    Name = "${var.title}-public_subnet_2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = aws_availability_zones.available_azs.names[0]

  tags = {
    Name = "${var.title}-private_subnet_1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = aws_availability_zones.available_azs.names[2]

  tags = {
    Name = "${var.title}-private_subnet_2"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.title}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  subnet_id         = aws_subnet.public_subnet_1.id
  connectivity_type = "public"
  allocation_id     = aws_eip.nat_eip.id

  tags = {
    Name = "${var.title}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    name = "${var.title} public rt"
  }
}

resource "aws_route_table_association" "public_rt_associations" {
  for_each = toset([
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ])

  subnet_id      = each.value
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }

  name = "${var.title} private rt"
}

resource "aws_route_table_association" "private_rt_associations" {
  for_each = toset([
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ])

  subnet_id      = each.value
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "Web security group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "bastion_sg" {
  name   = "Bastion security group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "Database security group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "db-sg"
  }
}

resource "aws_security_group" "lb_sg" {
  name   = "Load balancer security group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.title}lb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_allow_http" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "web_allow_https" {
  security_group_id = aws_security_group.web_sg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "web_allow_ssh" {
  security_group_id            = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "bastion_allow_ssh" {
  security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_http" {
  security_group_id = aws_security_group.lb_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "lb_allow_https" {
  security_group_id = aws_security_group.lb_sg.id
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

data "aws_ami" "main" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20260216.0-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer_key_pair" {
  key_name   = "deployer-key"
  public_key = var.deployer_public_key

  tags = {
    Name = "${var.title} Public key"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.main.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer_key_pair

  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_instance" "web_1" {
  ami                    = aws_ami.main.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = file("user-data/web_server_setup.sh")

  tags = {
    Name = "Web Server 1"
  }
}

resource "aws_instance" "web_2" {
  ami                    = aws_ami.main.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = file("user-data/web_server_setup.sh")

  tags = {
    Name = "Web Server 2"
  }
}

resource "aws_instance" "database" {
  ami                    = aws_ami.main.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  subnet_id              = aws_subnet.private_subnet_2.id

  user_data = file("user-data/db_server_setup.sh")

  tags = {
    Name = "Database Server"
  }
}

resource "aws_lb" "main" {
  name               = "${var.title}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.title}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/" # or your specific health endpoint
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "web_1_attachment" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2_attachment" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}