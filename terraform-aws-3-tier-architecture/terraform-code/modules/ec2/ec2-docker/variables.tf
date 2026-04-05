variable "aws_region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-east-2"

}

variable "instance_name" {
  description = "The name of the instance"
  type        = string
  default     = "tct-instance"

}

variable "ami_id" {
  description = "The AMI ID to use for the instance"
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type

}

variable "instance_type" {
  description = "The type of instance to create"
  type        = string
  default     = "t2.micro"

}

variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
  default     = "tct-key-pair" # Replace with your key pair name

}

variable "security_groups" {
  description = "The security groups to associate with the instance"
  type        = list(string)
  default     = ["tct-security-group"] # Replace with your security group name

}

variable "private_key_path" {
  description = "The path to the private key file for SSH access"
  type        = string
  default     = "./tct-key-pair.pem" # Replace with your private key path

}

variable "provisioner_commands" {
  description = "The commands to run on the instance after creation"
  type        = list(string)
  default = [
    "sudo apt-get update",
    "sudo apt-get install -y apache2",
    "sudo systemctl start apache2",
    "sudo systemctl enable apache2",
    "echo '<h1>Hello from Terraform!</h1>' | sudo tee /var/www/html/index.html"
  ]

}

variable "instance_user" {
  description = "The user to connect to the instance"
  type        = string
  default     = "ec2-user" # Change this if you're using a different AMI

}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in"
  type        = string
  default     = "subnet-0bb1c79de3EXAMPLE" # Replace with your subnet ID

}

variable "vpc_security_group_ids" {
  description = "The security group IDs to associate with the instance"
  type        = list(string)
  default     = ["sg-0bb1c79de3EXAMPLE"] # Replace with your security group ID

}
variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with the instance"
  type        = bool
  default     = false # Set to true if you want a public IP address, false otherwise

}

variable "tags" {
  description = "Tags to assign to the instance"
  type        = map(string)
  default = {
    Name        = "tct-instance"
    Environment = "Development"
    Project     = "Terraform-Cloud-Tutorial"
    Owner       = "YourName" # Replace with your name or team name
  }

}