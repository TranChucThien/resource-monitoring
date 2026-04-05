variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "my-default-bucket-name"

}

variable "environment" {
  description = "The environment for the S3 bucket"
  type        = string
  default     = "dev"

}

variable "versioning_status" {
  description = "The versioning status of the S3 bucket"
  type        = string
  default     = "Enabled"

}






