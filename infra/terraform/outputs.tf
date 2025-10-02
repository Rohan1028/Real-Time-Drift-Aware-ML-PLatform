output "kafka_bootstrap_servers" {
  value       = module.kafka.bootstrap_servers
  description = "Kafka bootstrap servers."
}

output "load_balancer_dns_name" {
  value       = module.load_balancer.load_balancer_dns_name
  description = "DNS name of the Application Load Balancer."
}

output "mlflow_url" {
  value       = "https://${module.load_balancer.load_balancer_dns_name}/mlflow"
  description = "MLflow tracking URL."
}

output "api_url" {
  value       = "https://${module.load_balancer.load_balancer_dns_name}"
  description = "API endpoint URL."
}

output "grafana_url" {
  value       = "https://${module.load_balancer.load_balancer_dns_name}/grafana"
  description = "Grafana dashboard URL."
}

output "vpc_id" {
  value       = module.network.vpc_id
  description = "ID of the VPC."
}

output "private_subnet_ids" {
  value       = module.network.private_subnet_ids
  description = "IDs of the private subnets."
}

output "public_subnet_ids" {
  value       = module.network.public_subnet_ids
  description = "IDs of the public subnets."
}

output "autoscaling_group_name" {
  value       = module.ec2.autoscaling_group_name
  description = "Name of the Auto Scaling Group."
}

output "redis_endpoint" {
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  description = "Redis endpoint for Feast online store."
}

output "postgres_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "PostgreSQL endpoint for Feast offline store."
}

output "s3_bucket_name" {
  value       = module.object_store.bucket_name
  description = "Name of the S3 bucket for ML artifacts."
}

output "codedeploy_application_name" {
  value       = module.codedeploy.application_name
  description = "Name of the CodeDeploy application"
}

output "codedeploy_deployment_group_name" {
  value       = module.codedeploy.deployment_group_name
  description = "Name of the CodeDeploy deployment group"
}

output "deployment_bucket_name" {
  value       = module.codedeploy.deployment_bucket_name
  description = "Name of the deployment artifacts bucket"
}
