resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_tag
  }
}

resource "aws_internet_gateway" "igw" {
  count  = var.create_and_attach_igw ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_tag}_igw"
  }
}