# Data source to reference the persistent DNS zone and certificate
data "aws_route53_zone" "main" {
  name = "acurley.dev"
}

data "aws_acm_certificate" "main" {
  domain   = "acurley.dev"
  statuses = ["ISSUED"]
}

# A record pointing to ALB for fusion subdomain (can be destroyed/recreated)
resource "aws_route53_record" "fusion" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "fusion.acurley.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Optional: Health subdomain A record (can be destroyed/recreated)
resource "aws_route53_record" "health" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "health.acurley.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
