variable "project" {
  type        = string
  description = "Project or environment identifier"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "autoscaling_group_name" {
  type        = string
  description = "Name of the Auto Scaling Group for deployments"
}

variable "deployment_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for deployment artifacts"
}

variable "alarm_names" {
  type        = list(string)
  description = "List of CloudWatch alarm names for deployment rollback"
  default     = []
}



