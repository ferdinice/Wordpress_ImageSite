# VPC (Network Foundation)
############################################

resource "aws_vpc" "ferdi_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ferdi-vpc"
  }
}

############################################
# PUBLIC SUBNETS
############################################

resource "aws_subnet" "ferdi_pubsub_1" {
  vpc_id            = aws_vpc.ferdi_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"

  tags = { Name = "ferdi-public-1" }
}

resource "aws_subnet" "ferdi_pubsub_2" {
  vpc_id            = aws_vpc.ferdi_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-3b"

  tags = { Name = "ferdi-public-2" }
}

############################################
# PRIVATE SUBNETS
############################################

resource "aws_subnet" "ferdi_prisub_1" {
  vpc_id            = aws_vpc.ferdi_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-3a"

  tags = { Name = "ferdi-private-1" }
}

resource "aws_subnet" "ferdi_prisub_2" {
  vpc_id            = aws_vpc.ferdi_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-3b"

  tags = { Name = "ferdi-private-2" }
}

############################################
# INTERNET GATEWAY
############################################

resource "aws_internet_gateway" "ferdi_igw" {
  vpc_id = aws_vpc.ferdi_vpc.id

  tags = { Name = "ferdi-igw" }
}

############################################
# NAT GATEWAY (PRIVATE INTERNET ACCESS)
############################################

resource "aws_eip" "ferdi_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "ferdi_nat" {
  allocation_id = aws_eip.ferdi_eip.id
  subnet_id     = aws_subnet.ferdi_pubsub_1.id

  tags = { Name = "ferdi-nat" }
}

############################################
# ROUTE TABLES
############################################

# Public Route Table
resource "aws_route_table" "ferdi_pub_rt" {
  vpc_id = aws_vpc.ferdi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ferdi_igw.id
  }
}

# Private Route Table
resource "aws_route_table" "ferdi_pri_rt" {
  vpc_id = aws_vpc.ferdi_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ferdi_nat.id
  }
}

############################################
# SECURITY GROUPS
############################################

# Frontend (Web Traffic)
resource "aws_security_group" "ferdi_frontend_sg" {
  vpc_id = aws_vpc.ferdi_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Backend (Database)
resource "aws_security_group" "ferdi_backend_sg" {
  vpc_id = aws_vpc.ferdi_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ferdi_frontend_sg.id]
  }
}


############################################
# RDS DATABASE (MySQL)
############################################

resource "aws_db_instance" "ferdi_rds" {
  allocated_storage    = 20
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin123"
  skip_final_snapshot  = true
  publicly_accessible  = false
}

############################################
# EC2 INSTANCE (WORDPRESS SERVER)
############################################

resource "aws_instance" "ferdi_ec2" {
  ami           = "ami-02efa8fd15663fc12"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.ferdi_pubsub_1.id

  vpc_security_group_ids = [
    aws_security_group.ferdi_frontend_sg.id
  ]

  associate_public_ip_address = true

  tags = {
    Name = "ferdi-wordpress-server"
  }
}

############################################
# LOAD BALANCER
############################################

resource "aws_lb" "ferdi_alb" {
  name               = "ferdi-alb"
  load_balancer_type = "application"
  subnets            = [
    aws_subnet.ferdi_pubsub_1.id,
    aws_subnet.ferdi_pubsub_2.id
  ]
}

############################################
# DOMAIN + DNS (ROUTE53)
############################################

data "aws_route53_zone" "ferdi_zone" {
  name = var.domain_name
}

resource "aws_route53_record" "ferdi_record" {
  zone_id = data.aws_route53_zone.ferdi_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.ferdi_alb.dns_name
    zone_id                = aws_lb.ferdi_alb.zone_id
    evaluate_target_health = true
  }
}