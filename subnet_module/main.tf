resource "aws_subnet" "subnet" {
  for_each = var.subnets
  cidr_block              = each.value[0]
  availability_zone       = each.value[1]
  map_public_ip_on_launch = each.value[2]
  vpc_id                  = var.vpc_id

  tags = {
    Name = each.key
  }
}