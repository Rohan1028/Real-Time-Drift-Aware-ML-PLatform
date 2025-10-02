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
  availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

# Random string for unique bucket names
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Network Infrastructure
module "network" {
  source              = "./modules/network"
  project             = var.project
  cidr                = var.vpc_cidr
  availability_zones  = local.availability_zones
}

# S3 Bucket for ML artifacts
module "object_store" {
  source      = "./modules/object_store"
  project     = var.project
  bucket_name = var.ml_bucket_name
  enable_gcp  = local.use_gcp
  region      = var.region
}

# Kafka/Event Streaming
module "kafka" {
  source            = "./modules/kafka"
  project           = var.project
  cluster_type      = var.kafka_cluster_type
  region            = var.region
  enable_gcp        = local.use_gcp
  vpc_id            = module.network.vpc_id
  vpc_cidr          = var.vpc_cidr
  subnet_ids        = module.network.private_subnet_ids
}

# Application Load Balancer
module "load_balancer" {
  source                = "./modules/load_balancer"
  project               = var.project
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  certificate_arn       = var.certificate_arn
  enable_deletion_protection = var.enable_deletion_protection
}

# Redis for Feast online store
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-redis-subnet-group"
  subnet_ids = module.network.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id         = "${var.project}-redis"
  description                  = "Redis for Feast online store"
  node_type                    = var.redis_node_type
  port                         = 6379
  parameter_group_name         = "default.redis7"
  num_cache_clusters           = 1
  automatic_failover_enabled   = false
  multi_az_enabled            = false
  subnet_group_name           = aws_elasticache_subnet_group.redis.name
  security_group_ids          = [aws_security_group.redis.id]
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true

  tags = {
    Name = "${var.project}-redis"
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.project}-redis-"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-redis-sg"
  }
}

# RDS PostgreSQL for Feast offline store and MLflow
resource "aws_db_instance" "postgres" {
  identifier = "${var.project}-postgres"

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = var.postgres_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "mlops"
  username = "mlops"
  password = var.postgres_password

  vpc_security_group_ids = [aws_security_group.postgres.id]
  db_subnet_group_name   = module.network.database_subnet_group_name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${var.project}-postgres"
  }
}

resource "aws_security_group" "postgres" {
  name_prefix = "${var.project}-postgres-"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-postgres-sg"
  }
}

# EC2 Auto Scaling Group for MLOps Platform
module "ec2" {
  source = "./modules/ec2"
  
  project                   = var.project
  region                    = var.region
  vpc_id                    = module.network.vpc_id
  vpc_cidr                  = var.vpc_cidr
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  ml_bucket_name            = var.ml_bucket_name
  kafka_bootstrap_servers   = module.kafka.bootstrap_servers
  redis_endpoint            = aws_elasticache_replication_group.redis.primary_endpoint_address
  postgres_endpoint         = aws_db_instance.postgres.endpoint
  target_group_arns         = [
    module.load_balancer.api_target_group_arn,
    module.load_balancer.mlflow_target_group_arn,
    module.load_balancer.grafana_target_group_arn
  ]

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Alarms for deployment rollback
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "MLOps/Platform"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High error rate detected"
  alarm_actions       = []

  dimensions = {
    Service = "serving"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "${var.project}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Latency"
  namespace           = "MLOps/Platform"
  period              = "300"
  statistic           = "Average"
  threshold           = "2000" # 2 seconds
  alarm_description   = "High latency detected"
  alarm_actions       = []

  dimensions = {
    Service = "serving"
  }
}

# CodeDeploy for automated deployments
module "codedeploy" {
  source = "./modules/codedeploy"
  
  project                   = var.project
  region                    = var.region
  autoscaling_group_name    = module.ec2.autoscaling_group_name
  deployment_bucket_name    = "${var.project}-deployment-artifacts-${random_string.bucket_suffix.result}"
  alarm_names              = [
    aws_cloudwatch_metric_alarm.high_error_rate.name,
    aws_cloudwatch_metric_alarm.high_latency.name
  ]
}
