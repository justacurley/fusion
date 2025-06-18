data "aws_network_interface" "interface_tags" {
  filter {
    name   = "tag:aws:ecs:serviceName"
    values = ["fusion"]
  }
  depends_on = [aws_ecs_service.app]
}

output "task_public_ip" {
  value = data.aws_network_interface.interface_tags.association[0].public_ip
}