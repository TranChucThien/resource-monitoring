provider "aws" {
  region = "us-east-2"
}

module "s3_bucket" {
  source      = "../modules/s3"
  bucket_name = "tct-three-tier-app"
}