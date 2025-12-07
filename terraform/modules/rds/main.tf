resource "random_password" "rds_password" {
  length  = 16
  special = true
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-db-subnet"
  subnet_ids = var.private_subnets
  tags = { Name = "${var.project}-db-subnet" }
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.project}-rds-sg"
  vpc_id = var.vpc_id
  description = "Allow MySQL from ECS"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # TODO: tighten to ECS SG later
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project}-mysql"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.instance_class
  name                    = var.db_name
  username                = var.db_username
  password                = random_password.rds_password.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  publicly_accessible     = false
  tags = { Name = "${var.project}-rds" }
}

output "endpoint" {
  value = aws_db_instance.mysql.address
}

output "port" {
  value = aws_db_instance.mysql.port
}

output "db_username" {
  value = var.db_username
}

output "db_password" {
  value = random_password.rds_password.result
}

output "db_name" {
  value = var.db_name
}
