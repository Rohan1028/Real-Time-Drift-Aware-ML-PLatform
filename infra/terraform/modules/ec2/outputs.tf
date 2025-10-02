output "autoscaling_group_name" {
  value       = aws_autoscaling_group.mlops_platform.name
  description = "Name of the Auto Scaling Group"
}

output "autoscaling_group_arn" {
  value       = aws_autoscaling_group.mlops_platform.arn
  description = "ARN of the Auto Scaling Group"
}

output "launch_template_id" {
  value       = aws_launch_template.mlops_platform.id
  description = "ID of the Launch Template"
}

output "launch_template_arn" {
  value       = aws_launch_template.mlops_platform.arn
  description = "ARN of the Launch Template"
}

output "security_group_id" {
  value       = aws_security_group.mlops_platform.id
  description = "ID of the security group"
}

output "instance_profile_arn" {
  value       = aws_iam_instance_profile.mlops_instance_profile.arn
  description = "ARN of the IAM instance profile"
}

