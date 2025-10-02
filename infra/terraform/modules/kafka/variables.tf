variable "project" {
  type        = string
  description = "Project or environment identifier"
}

variable "cluster_type" {
  type        = string
  default     = "msk"
  description = "Type of Kafka cluster (msk, kinesis, pubsub)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "enable_gcp" {
  type        = bool
  default     = false
  description = "Enable GCP instead of AWS"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the Kafka cluster will be created"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the Kafka cluster"
}



