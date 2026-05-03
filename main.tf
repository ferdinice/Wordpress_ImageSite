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