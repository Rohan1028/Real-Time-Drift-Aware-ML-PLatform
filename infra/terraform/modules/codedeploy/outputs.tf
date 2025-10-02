output "application_name" {
  value       = aws_codedeploy_application.mlops_platform.name
  description = "Name of the CodeDeploy application"
}

output "deployment_group_name" {
  value       = aws_codedeploy_deployment_group.mlops_platform.deployment_group_name
  description = "Name of the CodeDeploy deployment group"
}

output "service_role_arn" {
  value       = aws_iam_role.codedeploy_service_role.arn
  description = "ARN of the CodeDeploy service role"
}

output "ec2_instance_profile_arn" {
  value       = aws_iam_instance_profile.codedeploy_ec2_profile.arn
  description = "ARN of the EC2 instance profile for CodeDeploy"
}

output "deployment_bucket_name" {
  value       = aws_s3_bucket.deployment_artifacts.bucket
  description = "Name of the deployment artifacts bucket"
}

output "deployment_bucket_arn" {
  value       = aws_s3_bucket.deployment_artifacts.arn
  description = "ARN of the deployment artifacts bucket"
}



