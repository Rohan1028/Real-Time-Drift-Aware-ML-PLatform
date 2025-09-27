output "kafka_bootstrap_servers" {
  value       = "b-1.example.kafka.amazonaws.com:9092" # Placeholder
  description = "Kafka bootstrap servers (stub)."
}

output "mlflow_url" {
  value       = "https://mlflow.${var.project}.example.com"
  description = "MLflow tracking URL."
}
