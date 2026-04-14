variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "app_name" {
  description = "Application name for the ECR repository"
  type        = string
  default     = "app"
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed"
  type        = bool
  default     = true
}
