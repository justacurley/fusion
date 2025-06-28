# DNS A record for the main application
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "fusion.acurley.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Optional: Add www subdomain redirect (if needed)
resource "aws_route53_record" "www_app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.fusion.acurley.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}