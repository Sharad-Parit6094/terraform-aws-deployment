variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "aws_account_id" {
  type        = string
  description = "Your AWS account id"
  default     = ""
}

variable "project" {
  type    = string
  default = "cloudzenia-task"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "domain_name" {
  type        = string
  description = "Domain name to use for host based routing (e.g. example.com). If you don't have one, use a DDNS/subdomain."
  default     = ""
}

variable "certificate_arn" {
  type        = string
  description = "ACM Certificate ARN for HTTPS listener on ALB"
  default     = ""
}

variable "microservice_image_uri" {
  type        = string
  description = "ECR image URI for microservice (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/microservice:latest). Can be updated later."
  default     = ""
}

variable "ssh_key_name" {
  type    = string
  default = ""
  description = "Optional EC2 key pair name (imported in AWS) for SSH access to EC2 instances"
}
