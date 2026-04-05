# ============================================================
# General
# ============================================================
variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "three-tier-architecture"
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "dev"
}

# ============================================================
# Networking
# ============================================================
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (Web Tier)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_app_cidrs" {
  description = "Private subnet CIDRs (App Tier)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnet_db_cidrs" {
  description = "Private subnet CIDRs (Data Tier)"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24"]
}

# ============================================================
# Compute
# ============================================================
variable "instance_ami" {
  description = "AMI ID for EC2 instances (Amazon Linux 2)"
  type        = string
  default     = "ami-0ca4d5db4872d0c28"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "tct-key-pair"
}

# ============================================================
# ASG
# ============================================================
variable "asg_min" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "asg_desired" {
  description = "ASG desired capacity"
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "ASG maximum size"
  type        = number
  default     = 3
}

# ============================================================
# SSH Access
# ============================================================
variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into bastion host"
  type        = string
  default     = "0.0.0.0/0"
}

# ============================================================
# User Data (kept for backward compatibility)
# ============================================================
variable "user_data" {
  description = "Default user data script"
  type        = string
  default     = <<-EOF
#!/bin/bash
exec > /var/log/userdata.log 2>&1
set -ex
dnf update -y
dnf install -y httpd
systemctl enable --now httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
EOF
}

variable "user_data_db" {
  description = "User data script for DB instance"
  type        = string
  default     = <<-EOF
#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras enable docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
sudo yum install -y git
git clone https://github.com/TranChucThien/terraform-aws-3-tier-architecture.git
cd terraform-aws-3-tier-architecture/application/db
sudo mkdir -p /usr/libexec/docker/cli-plugins
sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/libexec/docker/cli-plugins/docker-compose
sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
sudo docker compose up -d
EOF
}
