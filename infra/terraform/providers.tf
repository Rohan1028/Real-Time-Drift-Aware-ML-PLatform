provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = var.project
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
