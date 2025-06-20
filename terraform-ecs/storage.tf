resource "aws_efs_mount_target" "ecs_persistence" {
  file_system_id  = data.aws_efs_file_system.psu.file_system_id
  subnet_id       = data.aws_subnet.default.id
  security_groups = [aws_security_group.efs_sg.id]
}

#trivy:ignore:AVD-AWS-0104 
resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Allow EFS access from ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
