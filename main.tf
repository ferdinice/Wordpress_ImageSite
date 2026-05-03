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