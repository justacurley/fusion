output "task_public_ip" {
  value = aws_ecs_service.app.network_configuration[0].assign_public_ip ? aws_ecs_service.app.network_configuration[0].public_ip : "N/A"
}