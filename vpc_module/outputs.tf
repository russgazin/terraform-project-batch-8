output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "igw_id" {
  value = var.create_and_attach_igw == true ? aws_internet_gateway.igw[0].id : null
}