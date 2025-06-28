# Route 53 Hosted Zone for domain management (PERSISTENT)
resource "aws_route53_zone" "main" {
  name = "acurley.dev"

  tags = {
    Name = "acurley.dev"
  }
}

# SSL Certificate from ACM (PERSISTENT)
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

# Certificate validation records (PERSISTENT)
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

# Certificate validation resource (PERSISTENT)
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

# Outputs for other Terraform configurations to reference
output "route53_zone_id" {
  description = "Route 53 Zone ID for domain records"
  value       = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  description = "Name servers to configure in GoDaddy"
  value       = aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate_validation.main.certificate_arn
}
