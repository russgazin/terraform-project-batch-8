output "ec2_ids" {
  value = [
    for i in aws_instance.instance : i.id
  ]
}
