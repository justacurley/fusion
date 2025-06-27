# Route 53 Hosted Zone for domain management
resource "aws_route53_zone" "main" {
  name = "acurley.dev"

  tags = {
    Name = "acurley.dev"
  }
}

# SSL Certificate from ACM
resource "aws_acm_certificate" "main" {
  domain_name               = "acurley.dev"
  subject_alternative_names = ["*.acurley.dev"]
  validation_method         = "DNS"

  tags = {
    Name = "acurley.dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Certificate validation resource
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "5m"
  }
}

# A record pointing to ALB for fusion subdomain
resource "aws_route53_record" "fusion" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "fusion.acurley.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Optional: Health subdomain A record
resource "aws_route53_record" "health" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "health.acurley.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Outputs for Route 53 resources
output "route53_name_servers" {
  description = "Name servers to configure in GoDaddy"
  value       = aws_route53_zone.main.name_servers
}

output "domain_url" {
  description = "Your fusion project URL"
  value       = "https://fusion.acurley.dev"
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate_validation.main.certificate_arn
}
