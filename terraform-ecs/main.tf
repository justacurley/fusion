

# ECS Cluster
#trivy:ignore:AVD-AWS-0034
resource "aws_ecs_cluster" "main" {
  name = "fusion"
}

# Security Group allowing internet access
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Allow inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/fusion"
  retention_in_days = 30
}

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "my-application"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "2048"
  memory = "4096"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
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
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "fusion"
    } }
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
  name                    = "fusion"
  cluster                 = aws_ecs_cluster.main.id
  task_definition         = aws_ecs_task_definition.app.arn
  desired_count           = 1
  launch_type             = "FARGATE"
  enable_ecs_managed_tags = true
  enable_execute_command  = true

  propagate_tags       = "TASK_DEFINITION"
  force_new_deployment = true # Had to add this to get tag propogation to work.
  network_configuration {
    subnets          = [data.aws_subnet.default.id] # Replace with your subnet IDs
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}

# # Note: To deploy your container image, you'll build and push to ECR manually or via CLI script below.