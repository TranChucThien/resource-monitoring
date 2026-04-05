variable "sg_name" {
  description = "Name of the security group"
  type        = string
  default     = "my-security-group"

}

variable "sg_description" {
  description = "Description of the security group"
  type        = string
  default     = "Security group for my EC2 instance"

}

variable "ingress_rules" {
  description = "List of ingress rules for security group"
  type = list(object({
    from_port = number
    to_port   = number
    protocol  = string
    # cidr_blocks = list(string)
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))



  # default = [
  #   { from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },   # SSH
  #   { from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },   # HTTP
  #   { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] }, # HTTPS
  # ]
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

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
  default     = "" # Set this to the VPC ID where you want to create the security group

}