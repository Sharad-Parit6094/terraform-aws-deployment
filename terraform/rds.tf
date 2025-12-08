resource "random_password" "rds_password" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = { Name = "${var.project}-${var.environment}-db-subnet-group" }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Allow MySQL from ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
    description     = "Allow MySQL from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "wordpress" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  name                   = "wordpress"
  username               = "wpadmin"
  password               = random_password.rds_password.result
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  backup_retention_period = 7
  publicly_accessible    = false
  tags = { Name = "${var.project}-${var.environment}-rds" }
}

# Store DB credentials in Secrets Manager as JSON
resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.project}-${var.environment}-db-credentials"
  description = "RDS credentials for WordPress"
}

resource "aws_secretsmanager_secret_version" "db_secret_ver" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    WORDPRESS_DB_HOST     = aws_db_instance.wordpress.address
    WORDPRESS_DB_USER     = aws_db_instance.wordpress.username
    WORDPRESS_DB_PASSWORD = random_password.rds_password.result
    WORDPRESS_DB_NAME     = aws_db_instance.wordpress.name
    WORDPRESS_DB_PORT     = aws_db_instance.wordpress.port
  })
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress.address
}

output "rds_port" {
  value = aws_db_instance.wordpress.port
}

output "rds_username" {
  value = aws_db_instance.wordpress.username
}

output "rds_password" {
  value     = random_password.rds_password.result
  sensitive = true
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}
