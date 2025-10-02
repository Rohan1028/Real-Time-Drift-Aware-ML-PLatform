output "load_balancer_arn" {
  value       = aws_lb.main.arn
  description = "ARN of the Application Load Balancer"
}

output "load_balancer_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "load_balancer_zone_id" {
  value       = aws_lb.main.zone_id
  description = "Zone ID of the Application Load Balancer"
}

output "api_target_group_arn" {
  value       = aws_lb_target_group.api.arn
  description = "ARN of the API target group"
}

output "mlflow_target_group_arn" {
  value       = aws_lb_target_group.mlflow.arn
  description = "ARN of the MLflow target group"
}

output "grafana_target_group_arn" {
  value       = aws_lb_target_group.grafana.arn
  description = "ARN of the Grafana target group"
}

output "security_group_id" {
  value       = aws_security_group.alb.id
  description = "ID of the load balancer security group"
}

