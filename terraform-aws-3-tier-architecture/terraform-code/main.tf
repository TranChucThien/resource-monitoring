# ============================================================
# Provider & Backend
# ============================================================
provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket       = "tct-three-tier-app"
    key          = "global/terraform.tfstate"
    region       = "us-east-2"
    use_lockfile = true
    encrypt      = true
  }
}

# ============================================================
# VPC
# ============================================================
module "vpc" {
  source                   = "./modules/vpc"
  name                     = "${var.project_name}-${var.environment}-vpc"
  azs                      = var.azs
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_app_cidrs = var.private_subnet_app_cidrs
  private_subnet_db_cidrs  = var.private_subnet_db_cidrs
}

# ============================================================
# Security Groups
# ============================================================
module "sg_presentation" {
  source  = "./modules/securitygroup"
  vpc_id  = module.vpc.vpc_id
  sg_name = "${var.project_name}-${var.environment}-sg-presentation"
  ingress_rules = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = [var.ssh_allowed_cidr] },
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 8000, to_port = 8000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = 3000, to_port = 3000, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { from_port = -1, to_port = -1, protocol = "icmp", cidr_blocks = ["0.0.0.0/0"] },
  ]
}

module "sg_app" {
  source  = "./modules/securitygroup"
  vpc_id  = module.vpc.vpc_id
  sg_name = "${var.project_name}-${var.environment}-sg-app"
  ingress_rules = [
    { from_port = 8080, to_port = 8080, protocol = "tcp", security_groups = [module.sg_presentation.security_group_id] },
    { from_port = 22, to_port = 22, protocol = "tcp", security_groups = [module.sg_presentation.security_group_id] },
    { from_port = 8000, to_port = 8000, protocol = "tcp", security_groups = [module.sg_presentation.security_group_id] },
    { from_port = 3000, to_port = 3000, protocol = "tcp", security_groups = [module.sg_presentation.security_group_id] },
  ]
}

module "sg_db" {
  source  = "./modules/securitygroup"
  vpc_id  = module.vpc.vpc_id
  sg_name = "${var.project_name}-${var.environment}-sg-db"
  ingress_rules = [
    { from_port = 27017, to_port = 27017, protocol = "tcp", security_groups = [module.sg_app.security_group_id] },
    { from_port = 22, to_port = 22, protocol = "tcp", security_groups = [module.sg_app.security_group_id] },
  ]
}

# ============================================================
# EC2 Instances
# ============================================================
module "ec2_bastion_host" {
  source             = "./modules/ec2/ec2"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  key_name           = var.key_name
  ec2_name           = "${var.project_name}-${var.environment}-bastion"
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.sg_presentation.security_group_id]
}

module "ec2_db" {
  source             = "./modules/ec2/ec2"
  instance_ami       = var.instance_ami
  instance_type      = var.instance_type
  key_name           = var.key_name
  ec2_name           = "${var.project_name}-${var.environment}-db"
  subnet_id          = module.vpc.private_subnet_db_ids[0]
  security_group_ids = [module.sg_db.security_group_id]
  user_data          = var.user_data_db
}

# ============================================================
# Target Groups
# ============================================================
module "target_group_frontend" {
  source                = "./modules/target_group"
  target_group_name     = "${var.project_name}-${var.environment}-fe-tg"
  target_group_port     = 3000
  target_group_protocol = "HTTP"
  vpc_id                = module.vpc.vpc_id
  instance_ids          = []
}

module "target_group_backend" {
  source                = "./modules/target_group"
  target_group_name     = "${var.project_name}-${var.environment}-be-tg"
  target_group_port     = 8000
  target_group_protocol = "HTTP"
  vpc_id                = module.vpc.vpc_id
  instance_ids          = []
}

# ============================================================
# Load Balancer
# ============================================================
module "load_balancer" {
  source             = "./modules/load_balancer"
  load_balancer_name = "${var.project_name}-${var.environment}-alb"
  internal           = false
  security_group_ids = [module.sg_presentation.security_group_id]
  subnet_ids         = module.vpc.public_subnet_ids
  target_groups = [
    {
      port             = 80
      protocol         = "HTTP"
      target_group_arn = module.target_group_frontend.target_group_arn
    },
    {
      port             = 8000
      protocol         = "HTTP"
      target_group_arn = module.target_group_backend.target_group_arn
    }
  ]
}

# ============================================================
# Auto Scaling Groups
# ============================================================
module "asg_frontend" {
  source               = "./modules/asg"
  launch_template_name = "${var.project_name}-${var.environment}-lt-fe"
  ami_id               = var.instance_ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  user_data            = base64encode(templatefile("templates/user_data_fe.sh", { be_private_ip = module.load_balancer.alb_dns_name }))
  security_group_ids   = [module.sg_app.security_group_id]
  min_size             = var.asg_min
  desired_capacity     = var.asg_desired
  max_size             = var.asg_max
  vpc_zone_identifiers = module.vpc.private_subnet_app_ids
  target_group_arns    = [module.target_group_frontend.target_group_arn]
}

module "asg_backend" {
  source               = "./modules/asg"
  launch_template_name = "${var.project_name}-${var.environment}-lt-be"
  ami_id               = var.instance_ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  user_data            = base64encode(templatefile("templates/user_data_be.sh", { db_private_ip = module.ec2_db.private_ip }))
  security_group_ids   = [module.sg_app.security_group_id]
  min_size             = var.asg_min
  desired_capacity     = var.asg_desired
  max_size             = var.asg_max
  vpc_zone_identifiers = module.vpc.private_subnet_app_ids
  target_group_arns    = [module.target_group_backend.target_group_arn]
}
