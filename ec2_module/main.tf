# launch an EC2 instances:
resource "aws_instance" "instance" {
  for_each               = var.instances
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.ec2_sg
  user_data              = var.user_data
  subnet_id              = each.value

  tags = {
    Name = each.key
  }
}
