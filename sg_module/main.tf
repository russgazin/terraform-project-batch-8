resource "aws_security_group" "security_group" {
  name   = var.sg_name
  vpc_id = var.vpc_id

  tags = {
    Name = var.sg_tag
  }
}

resource "aws_security_group_rule" "rule" {
  for_each                 = var.sg_rules
  type                     = each.value[0]
  cidr_blocks              = length(each.value[1]) <= 18 ? [each.value[1]] : null
  source_security_group_id = startswith(each.value[1], "sg-") ? each.value[1] : null
  from_port                = each.value[2]
  to_port                  = each.value[3]
  protocol                 = each.value[4]
  description              = each.key
  security_group_id        = aws_security_group.security_group.id
}