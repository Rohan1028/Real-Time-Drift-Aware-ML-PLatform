output "cluster_arn" {
  value       = aws_msk_cluster.main.arn
  description = "ARN of the MSK cluster"
}

output "bootstrap_servers" {
  value       = aws_msk_cluster.main.bootstrap_brokers_sasl_iam
  description = "Bootstrap servers for Kafka clients"
}

output "cluster_name" {
  value       = aws_msk_cluster.main.cluster_name
  description = "Name of the MSK cluster"
}

output "security_group_id" {
  value       = aws_security_group.kafka.id
  description = "ID of the Kafka security group"
}

output "kms_key_id" {
  value       = aws_kms_key.kafka.key_id
  description = "KMS key ID used for encryption"
}



