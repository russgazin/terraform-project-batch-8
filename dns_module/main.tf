# lookup route53 hosted zones:
data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone
  private_zone = false
}

# create route53 cname record to map to alb dns name:
resource "aws_route53_record" "my_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = var.record_name
  type    = var.record_type
  ttl     = var.record_ttl
  records = var.record_records
}
