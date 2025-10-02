variable "project" {
  type        = string
  description = "Project or environment identifier"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the load balancer will be created"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the load balancer"
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the SSL certificate for HTTPS"
  default     = ""
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for the load balancer"
  default     = false
}

