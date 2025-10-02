variable "project" {
  type        = string
  description = "Project or environment identifier."
}

variable "region" {
  type        = string
  description = "Cloud region for deployment."
  default     = "us-east-1"
}

variable "enable_gcp" {
  type    = bool
  default = false
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ml_bucket_name" {
  type        = string
  description = "Name of S3/GCS bucket for artifacts."
}

variable "kafka_cluster_type" {
  type        = string
  default     = "msk"
  description = "msk | kinesis | pubsub"
}
