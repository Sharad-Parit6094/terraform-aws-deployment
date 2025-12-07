# AWS ECS, ALB, RDS, EC2, NGINX, Secrets Manager, CI/CD using Terraform & GitHub Actions.
The project provisions AWS infrastructure using Terraform, deploys WordPress + Microservice on ECS, configures RDS, and deploys EC2 Instances with NGINX + Docker, along with CI/CD using GitHub Actions.

##🚀 Project Overview
This project demonstrates:
Infrastructure as Code using Terraform
Container deployments on Amazon ECS
WordPress deployed using private ECS service + RDS database
Custom Node.js microservice deployed on ECS
Secrets stored in AWS Secrets Manager
EC2 instances serving content using NGINX and Docker
Secure ALB with HTTPS + Domain Mapping
CloudWatch logs & metrics
GitHub Actions for CI/CD pipeline
Optional S3 static hosting with CloudFront

##⚙️ Infrastructure Components
AWS Services Used-
ECS (Fargate)
EC2
RDS (MySQL/Aurora)
Secrets Manager
IAM
VPC (Private + Public Subnets)
Internet Gateway
NAT Gateway
Application Load Balancer
Route53
CloudWatch Logs & Metrics
ECR
S3 + CloudFront (Optional)

##🔐 Security
IAM roles with least privilege
All workloads in private subnets
HTTPS enabled using SSL certificates
HTTP → HTTPS redirection
Secrets stored in Secrets Manager
No hardcoded credentials
