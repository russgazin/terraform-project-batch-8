output "subnet_ids" {
  value = [
    for subnet in aws_subnet.subnet : subnet.id
  ]
}