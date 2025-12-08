output "alb_dns" {
  value = aws_lb.alb.dns_name
}

output "wordpress_url" {
  value = "https://wordpress.${var.domain_name}"
}

output "microservice_url" {
  value = "https://microservice.${var.domain_name}"
}

output "ec2_instance1_ip" {
  value = aws_eip.app1_eip.public_ip
}

output "ec2_instance2_ip" {
  value = aws_eip.app2_eip.public_ip
}

output "ec2_instance1_url" {
  value = "http://${aws_eip.app1_eip.public_ip}" # use HTTP until you configure Let's Encrypt/ALB
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress.address
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_secret.arn
}
