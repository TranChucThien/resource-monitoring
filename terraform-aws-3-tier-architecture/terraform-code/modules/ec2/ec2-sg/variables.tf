variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "instance_ami" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "ec2_name" {
  description = "Tag name for EC2 instance"
  type        = string
  default     = "MyEC2Instance"
}

variable "sg_name" {
  description = "Security group name"
  type        = string
  default     = "my_security_group"
}

variable "sg_description" {
  description = "Description of security group"
  type        = string
  default     = "Allow SSH and HTTP access"
}

variable "ingress_rules" {
  description = "List of ingress rules for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },   # SSH
    { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },   # HTTP
    { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }, # HTTPS
  ]
}

variable "egress_rules" {
  description = "List of egress rules for security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"] }
  ]

}

variable "key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
  default     = "./tct-key-pair.pem" # Đường dẫn đến private key

}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string


}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the EC2 instance"
  type        = list(string)
  default     = []

}

variable "vpc_id" {
  description = "VPC ID where the security group is located"
  type        = string


}

variable "connection_type" {
  description = "Connection type for remote execution"
  type        = string
  default     = "ssh" # or "winrm" for Windows instances

}

variable "user" {
  description = "Username for SSH connection"
  type        = string
  default     = "ubuntu" # or "ec2-user" for Amazon Linux
}

variable "provisioner_commands" {
  description = "Commands to run on the EC2 instance after provisioning"
  type        = list(string)
  default = [
    "sudo apt update -y",
    "sudo apt install -y nginx",
    "sudo systemctl start nginx",
    "sudo systemctl enable nginx",
  ]


}