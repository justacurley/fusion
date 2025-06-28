# ALB outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

# Application URL
output "application_url" {
  description = "URL to access the application"
  value       = "https://fusion.acurley.dev"
}

# ECS Service info
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# DNS record outputs
output "app_domain" {
  description = "The domain name where the application is accessible"
  value       = aws_route53_record.app.fqdn
}