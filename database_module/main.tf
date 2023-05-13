resource "aws_db_subnet_group" "subnet_group" {
  name       = var.db_subnet_group_name
  subnet_ids = var.db_subnet_group_subnet_ids

  tags = {
    Name = var.db_subnet_group_tag
  }
}

resource "aws_db_instance" "db" {
  allocated_storage           = var.allocated_storage
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  db_name                     = var.db_name
  username                    = var.username
  password                    = var.password
  vpc_security_group_ids      = var.security_group_ids
  db_subnet_group_name        = aws_db_subnet_group.subnet_group.name
  multi_az                    = false
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false
  skip_final_snapshot         = true
}
