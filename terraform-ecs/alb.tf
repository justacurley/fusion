# Application Load Balancer
resource "aws_lb" "main" {
  name               = "fusion-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  # Use your existing subnet data sources
  subnets = [data.aws_subnet.default.id, data.aws_subnet.secondary.id]

  enable_deletion_protection = false

  tags = {
    Name = "fusion-alb"
  }
}

# Security Group for ALB
#trivy:ignore:AVD-AWS-0104
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg-"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group for ECS Service
resource "aws_lb_target_group" "app" {
  name        = "fusion-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/v1/status"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "fusion-target-group"
  }
}

# ALB Listener for HTTP (redirects to HTTPS)
# This listener is handled by the http_redirect listener below

# ALB Listener for HTTPS
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# HTTP to HTTPS redirect
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Output ALB information
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}
