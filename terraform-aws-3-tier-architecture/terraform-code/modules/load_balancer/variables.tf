variable "load_balancer_name" {
  description = "The name of the load balancer."
  type        = string
  default = "three-tier-alb"
  
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach to the load balancer."
  type        = list(string)
  
  
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the load balancer."
  type        = list(string)
  
}

variable "internal" {
  description = "Boolean to indicate if the load balancer is internal."
  type        = bool
  default     = false
  
}

variable "target_groups" {
  description = "List of target group configurations."
  type = list(object({
    target_group_arn = string
    port             = number
    protocol         = string
  }))
  
  
}