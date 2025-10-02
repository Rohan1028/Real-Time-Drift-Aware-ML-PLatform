variable "project" {
  type        = string
  description = "Project or environment identifier"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "min_size" {
  type        = number
  description = "Minimum number of instances in Auto Scaling Group"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of instances in Auto Scaling Group"
  default     = 5
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of instances in Auto Scaling Group"
  default     = 2
}

variable "ml_bucket_name" {
  type        = string
  description = "S3 bucket name for ML artifacts"
}

variable "kafka_bootstrap_servers" {
  type        = string
  description = "Kafka bootstrap servers"
}

variable "redis_endpoint" {
  type        = string
  description = "Redis endpoint for Feast online store"
}

variable "postgres_endpoint" {
  type        = string
  description = "PostgreSQL endpoint for Feast offline store"
}

variable "target_group_arns" {
  type        = list(string)
  description = "List of target group ARNs for the Auto Scaling Group"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to resources"
  default     = {}
}

