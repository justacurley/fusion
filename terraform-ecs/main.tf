
# # IAM Roles & Policies for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_task_exec_efs_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}


# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "fusion"
}

# Security Group allowing internet access
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["${var.my_pip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "my-application"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu                      = "2048"
  memory                   = "4096"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "PSUniversal"
    image     = "${data.aws_ecr_repository.my_repo.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
    mountPoints = [{
      sourceVolume  = "efs-volume"
      containerPath = "/home/data"
      readOnly      = false
    }]
  }])
  volume {
    name = "efs-volume"
    efs_volume_configuration {
      file_system_id = data.aws_efs_file_system.psu.id
      root_directory = "/"
    }
  }
}

# ECS Service (to run the task)
resource "aws_ecs_service" "app" {
  name            = "fusion"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id] # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# # Note: To deploy your container image, you'll build and push to ECR manually or via CLI script below.