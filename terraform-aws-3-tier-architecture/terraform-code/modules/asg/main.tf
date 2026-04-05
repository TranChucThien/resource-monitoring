

variable "launch_template_name" {
  description = "The name of the launch template"
  type        = string
  default     = "my_launch_template"
  
}
variable "ami_id" {
  description = "The AMI ID for the EC2 instances"
  type        = string
  
}

variable "instance_type" {
  description = "The instance type for the EC2 instances"
  type        = string
  default     = "t2.micro"
  
}

variable "key_name" {
  description = "The key pair name for SSH access"
  type        = string
  
}

variable "user_data" {
  description = "User data script to initialize the EC2 instance"
  type        = string
  default     = null # You can provide a default user data script here if needed

}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the EC2 instances"
  type        = list(string)
  default     = []
  
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling group"
  type        = number
  default     = 1
  
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling group"
  type        = number
  default     = null
  
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling group"
  type        = number
  default     = null
  
}

variable "vpc_zone_identifiers" {
  description = "List of subnet IDs for the Auto Scaling group"
  type        = list(string)
  
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach to the Auto Scaling group"
  type        = list(string)
  default     = null
  
}

resource "aws_launch_template" "this" {
    name = var.launch_template_name
    image_id = var.ami_id
    instance_type = var.instance_type
    key_name = var.key_name
    user_data = var.user_data
    vpc_security_group_ids = var.security_group_ids

}


resource "aws_autoscaling_group" "this" {

    desired_capacity     = var.desired_capacity != null ? var.desired_capacity : var.min_size
    max_size             = var.max_size != null ? var.max_size : 2
    min_size             = var.min_size != null ? var.min_size : 1
    launch_template {
        id      = aws_launch_template.this.id
        version = "$Latest"
    }
    vpc_zone_identifier = var.vpc_zone_identifiers
    target_group_arns = var.target_group_arns != null ? var.target_group_arns : []


}


output "launch_template_id" {
  value       = aws_launch_template.this.id
  description = "The ID of the launch template."
  
}

