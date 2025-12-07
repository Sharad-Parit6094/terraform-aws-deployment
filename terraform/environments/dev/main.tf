locals {
  name_prefix = "${var.project}-${var.environment}"
}

module "vpc" {
  source  = "../../modules/vpc"
  project = local.name_prefix
}

module "iam" {
  source  = "../../modules/iam"
  project = local.name_prefix
}

module "rds" {
  source          = "../../modules/rds"
  project         = local.name_prefix
  private_subnets = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  db_username     = "wpadmin"
  db_name         = "wordpress"
  instance_class  = "db.t3.micro"  # small for free-tier eligible accounts (if supported)
}

module "secrets" {
  source     = "../../modules/secretsmanager"
  project    = local.name_prefix
  db_username = module.rds.db_username
  db_password = module.rds.db_password
  db_host     = module.rds.endpoint
  db_port     = module.rds.port
  db_name     = module.rds.db_name
}

module "ecs" {
  source                 = "../../modules/ecs"
  project                = local.name_prefix
  vpc_id                 = module.vpc.vpc_id
  private_subnets        = module.vpc.private_subnets
  public_subnets         = module.vpc.public_subnets
  microservice_image_uri = var.microservice_image_uri
  secrets_arn            = module.secrets.secret_arn
}

module "alb" {
  source         = "../../modules/alb"
  project        = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  domain_name    = var.domain_name
  certificate_arn = var.certificate_arn
  wordpress_tg_arn = module.ecs.wordpress_tg_arn
  microservice_tg_arn = module.ecs.microservice_tg_arn
}

module "ec2" {
  source = "../../modules/ec2"
  project = local.name_prefix
  public_subnets = module.vpc.public_subnets
  domain_name = var.domain_name
}

output "alb_dns" {
  value = module.alb.alb_dns
}

output "rds_endpoint" {
  value = module.rds.endpoint
}
