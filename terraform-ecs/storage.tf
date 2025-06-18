resource "aws_efs_file_system" "ecs_persistence" {
  creation_token = "ecs-persistence"
  encrypted      = true
  tags = {
    Name = "ECS Persistent Storage"
  }
}

resource "aws_efs_mount_target" "ecs_persistence" {
  file_system_id  = aws_efs_file_system.ecs_persistence.id
  subnet_id       = data.aws_subnet.default.id
  security_groups = [aws_security_group.efs_sg.id]
}

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
