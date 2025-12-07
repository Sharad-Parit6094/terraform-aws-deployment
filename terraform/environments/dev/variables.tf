variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "project" {
  type    = string
  default = "cloudzenia"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "domain_name" {
  type = string
  description = "Domain name to use (e.g. example.com) - required for ALB hostnames"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS on ALB (must be in same region)"
  default     = ""
}

variable "microservice_image_uri" {
  type = string
  description = "ECR image URI for microservice (set after first push)."
  default = ""
}

variable "aws_account_id" {
  type = string
  description = "AWS Account ID - used for ECR and IAM"
  default = ""
}
