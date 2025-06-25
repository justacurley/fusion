data "aws_network_interface" "interface_tags" {
  filter {
    name   = "tag:aws:ecs:serviceName"
    values = ["fusion"]
  }
  # Create filter for the eni description
  filter {
    name   = "description"
    values = ["arn:aws:ecs*"]
  }
  depends_on = [aws_ecs_service.app, aws_efs_mount_target.ecs_persistence]
}

output "task_public_uri" {
  value = "http://${data.aws_network_interface.interface_tags.association[0].public_ip}:5000"
}