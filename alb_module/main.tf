resource "aws_lb" "alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = var.load_balancer_type
  security_groups    = var.alb_sg
  subnets            = var.alb_subnets

  tags = {
    Name = var.alb_tag
  }
}

# adding port80 listener to alb:
resource "aws_lb_listener" "http_listenter" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on        = [aws_lb_listener.https_listener]

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# data call for ssl certificate:
data "aws_acm_certificate" "issued" {
  domain   = var.alb_https_listener_certificate_domain
  statuses = ["ISSUED"]
}

# adding port443 listener to alb:
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn
  depends_on        = [aws_lb.alb]

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}
