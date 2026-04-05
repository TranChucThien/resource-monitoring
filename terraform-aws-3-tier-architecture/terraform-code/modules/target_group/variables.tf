variable "target_group_name" {
  description = "The name of the target group."
  type        = string
}

variable "target_group_port" {
  description = "The port on which the target group is listening."
  type        = number
  default     = 80
}

variable "target_group_protocol" {
  description = "The protocol to use for routing traffic to the targets."
  type        = string
  default     = "HTTP"
}

variable "vpc_id" {
  description = "The ID of the VPC where the target group will be created."
  type        = string
}

variable "instance_ids" {
  description = "List of instance IDs to register with the target group."
  type        = list(string)
  default     = []
}
