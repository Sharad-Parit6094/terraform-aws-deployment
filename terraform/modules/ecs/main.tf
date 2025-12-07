resource "aws_ecs_cluster" "this" {
  name = "${var.project}-ecs-cluster"
}

# Execution role for tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals { type = "Service" ; identifiers = ["ecs-tasks.amazonaws.com"] }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow SecretsManager read
resource "aws_iam_policy" "secrets_read_policy" {
  name = "${var.project}-secrets-read"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_read_policy.arn
}

# WordPress task definition (Fargate)
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project}-wordpress"
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name = "wordpress",
      image = "wordpress:6.2-apache",
      essential = true,
      portMappings = [{ containerPort = 80, protocol = "tcp" }],
      environment = [],
      secrets = [
        { name = "WORDPRESS_DB_HOST", valueFrom = var.secrets_arn },
        { name = "WORDPRESS_DB_USER", valueFrom = var.secrets_arn },
        { name = "WORDPRESS_DB_PASSWORD", valueFrom = var.secrets_arn }
      ]
    }
  ])
}

# Microservice task definition
resource "aws_ecs_task_definition" "microservice" {
  family                   = "${var.project}-microservice"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name = "microservice",
      image = var.microservice_image_uri != "" ? var.microservice_image_uri : "public.ecr.aws/bitnami/node:18",
      essential = true,
      portMappings = [{ containerPort = 8080, protocol = "tcp" }],
    }
  ])
}

# Create Target Groups for ALB
resource "aws_lb_target_group" "wordpress_tg" {
  name     = "${var.project}-wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "microservice_tg" {
  name     = "${var.project}-micro-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    path = "/"
    protocol = "HTTP"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# ECS Services
resource "aws_ecs_service" "wordpress" {
  name            = "${var.project}-wordpress-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnets
    assign_public_ip = false
    security_groups = [var.ecs_sg_id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
    container_name   = "wordpress"
    container_port   = 80
  }
  depends_on = [aws_iam_role_policy_attachment.ecs_task_policy_attach]
}

resource "aws_ecs_service" "microservice" {
  name            = "${var.project}-microservice-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = var.private_subnets
    assign_public_ip = false
    security_groups = [var.ecs_sg_id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.microservice_tg.arn
    container_name   = "microservice"
    container_port   = 8080
  }
}

output "wordpress_tg_arn" {
  value = aws_lb_target_group.wordpress_tg.arn
}

output "microservice_tg_arn" {
  value = aws_lb_target_group.microservice_tg.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}
