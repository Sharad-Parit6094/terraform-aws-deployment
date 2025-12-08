resource "aws_ecs_cluster" "ecs" {
  name = "${var.project}-${var.environment}-cluster"
}

# ECR repo for microservice (optional)
resource "aws_ecr_repository" "microservice" {
  name = "microservice"
}

# WordPress Task Definition (Fargate) - uses public wordpress image
locals {
  wp_container_def = jsonencode([
    {
      name = "wordpress"
      image = "wordpress:6.2-apache"
      essential = true
      portMappings = [{ containerPort = 80, protocol = "tcp" }]
      environment = []
      secrets = [
        {
          name = "WORDPRESS_DB_HOST"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:WORDPRESS_DB_HOST"
        },
        {
          name = "WORDPRESS_DB_USER"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:WORDPRESS_DB_USER"
        },
        {
          name = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:WORDPRESS_DB_PASSWORD"
        },
        {
          name = "WORDPRESS_DB_NAME"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:WORDPRESS_DB_NAME"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project}-${var.environment}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions    = local.wp_container_def
}

# Microservice task definition
locals {
  micro_container_def = jsonencode([
    {
      name = "microservice"
      image = length(var.microservice_image_uri) > 0 ? var.microservice_image_uri : "${aws_ecr_repository.microservice.repository_url}:latest"
      essential = true
      portMappings = [{ containerPort = 3000, protocol = "tcp" }]
      environment = []
    }
  ])
}

resource "aws_ecs_task_definition" "microservice" {
  family                   = "${var.project}-${var.environment}-microservice"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions    = local.micro_container_def
}

# Target groups
resource "aws_lb_target_group" "wordpress_tg" {
  name        = "${var.project}-wp-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "micro_tg" {
  name        = "${var.project}-micro-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener rules - host based
resource "aws_lb_listener_rule" "wordpress_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
  condition {
    host_header {
      values = ["wordpress.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "micro_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.micro_tg.arn
  }
  condition {
    host_header {
      values = ["microservice.${var.domain_name}"]
    }
  }
}

# ECS services
resource "aws_ecs_service" "wordpress_service" {
  name            = "${var.project}-${var.environment}-wordpress-svc"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
    container_name   = "wordpress"
    container_port   = 80
  }
  depends_on = [aws_lb_listener.https]
}

resource "aws_ecs_service" "micro_service" {
  name            = "${var.project}-${var.environment}-micro-svc"
  cluster         = aws_ecs_cluster.ecs.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.micro_tg.arn
    container_name   = "microservice"
    container_port   = 3000
  }
  depends_on = [aws_lb_listener.https]
}
