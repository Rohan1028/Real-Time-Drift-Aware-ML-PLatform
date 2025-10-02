# CodeDeploy Module for Automated Deployments
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}

# CodeDeploy Application
resource "aws_codedeploy_application" "mlops_platform" {
  compute_platform = "Server"
  name             = "${var.project}-mlops-platform"

  tags = {
    Name = "${var.project}-mlops-platform"
  }
}

# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "mlops_platform" {
  app_name              = aws_codedeploy_application.mlops_platform.name
  deployment_group_name = "${var.project}-mlops-platform-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  autoscaling_groups = [var.autoscaling_group_name]

  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "${var.project}-mlops-platform"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = var.alarm_names
    enabled = length(var.alarm_names) > 0
  }

  tags = {
    Name = "${var.project}-mlops-platform-deployment-group"
  }
}

# IAM Role for CodeDeploy Service
resource "aws_iam_role" "codedeploy_service_role" {
  name = "${var.project}-codedeploy-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-codedeploy-service-role"
  }
}

# IAM Policy for CodeDeploy Service
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# IAM Role for EC2 instances to work with CodeDeploy
resource "aws_iam_role" "codedeploy_ec2_role" {
  name = "${var.project}-codedeploy-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-codedeploy-ec2-role"
  }
}

# IAM Policy for CodeDeploy EC2 role
resource "aws_iam_role_policy_attachment" "codedeploy_ec2_role_policy" {
  role       = aws_iam_role.codedeploy_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Policy for S3 access for deployment artifacts
resource "aws_iam_role_policy" "codedeploy_s3_policy" {
  name = "${var.project}-codedeploy-s3-policy"
  role = aws_iam_role.codedeploy_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.deployment_bucket_name}",
          "arn:aws:s3:::${var.deployment_bucket_name}/*"
        ]
      }
    ]
  })
}

# Instance Profile for CodeDeploy
resource "aws_iam_instance_profile" "codedeploy_ec2_profile" {
  name = "${var.project}-codedeploy-ec2-profile"
  role = aws_iam_role.codedeploy_ec2_role.name

  tags = {
    Name = "${var.project}-codedeploy-ec2-profile"
  }
}

# S3 Bucket for deployment artifacts
resource "aws_s3_bucket" "deployment_artifacts" {
  bucket = var.deployment_bucket_name

  tags = {
    Name        = "${var.project}-deployment-artifacts"
    Purpose     = "CodeDeploy Artifacts"
    Environment = var.project
  }
}

resource "aws_s3_bucket_versioning" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deployment_artifacts" {
  bucket = aws_s3_bucket.deployment_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CodeDeploy Agent installation script
locals {
  codedeploy_install_script = templatefile("${path.module}/install_codedeploy_agent.sh", {
    region = var.region
  })
}



