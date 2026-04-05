variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
  
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "three-tier-app"
  
}

provider "aws" {
  region = "us-east-2"

}



terraform {
    backend "s3" {
        bucket = "tct-three-tier-app"
        key    = "global/terraform.tfstate"
        region = "us-east-2"
        use_lockfile = true
        encrypt = true
    }
}

module "vpc" {
  source = "./modules/vpc"
  name   = "${var.project_name}-vpc"
  azs = [ "us-east-2a", "us-east-2b" ]
  public_subnet_cidrs = [ "10.0.1.0/24", "10.0.2.0/24" ]
  private_subnet_app_cidrs = [ "10.0.101.0/24", "10.0.102.0/24" ]
  private_subnet_db_cidrs = ["10.0.201.0/24", "10.0.202.0/24",]
}