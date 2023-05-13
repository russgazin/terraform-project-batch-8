resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = var.subnet_id
  depends_on    = [aws_eip.natgw_eip]

  tags = {
    Name = var.nat_gateway_tag
  }
}

resource "aws_eip" "natgw_eip" {
  vpc = true

  tags = {
    Name = var.eip_tag
  }
}
