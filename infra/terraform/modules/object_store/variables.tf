variable "project" {
  type        = string
  description = "Project or environment identifier"
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for ML artifacts"
}

variable "enable_gcp" {
  type        = bool
  default     = false
  description = "Enable GCP instead of AWS"
}

variable "region" {
  type        = string
  description = "AWS region"
}



