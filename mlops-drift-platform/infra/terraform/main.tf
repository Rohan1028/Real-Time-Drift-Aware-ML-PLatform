terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.15"
    }
  }
}

locals {
  use_gcp = var.enable_gcp
}

module "network" {
  source = "./modules/network" # Stub - add implementation
  project = var.project
  cidr    = var.vpc_cidr
}

module "object_store" {
  source      = "./modules/object_store"
  project     = var.project
  bucket_name = var.ml_bucket_name
  enable_gcp  = local.use_gcp
  region      = var.region
}

module "kafka" {
  source            = "./modules/kafka"
  project           = var.project
  cluster_type      = var.kafka_cluster_type
  region            = var.region
  enable_gcp        = local.use_gcp
}
