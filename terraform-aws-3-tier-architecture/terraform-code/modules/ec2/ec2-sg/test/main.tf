provider "aws" {
  region = "us-east-2" # Specify the AWS region

}


module "ec2" {
  source   = "./module/ec2" # Path to the module directory
  key_name = "tct-key-pair"
  ec2_name = "tct-ec2-instance"   # Example tag name for EC2 instance, can be overridden
  key_path = "./tct-key-pair.pem" # Path to the private key file
  ingress_rules = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },   # SSH
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },   # HTTP
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }, # HTTPS
  ]
  sg_description = "SG with SSH and HTTP/HTTPS access"
  vpc_id         = "vpc-02685dfbe59b1036e"
  subnet_id      = "subnet-030f6b424e5aff37b"
}

