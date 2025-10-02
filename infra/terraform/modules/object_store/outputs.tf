output "bucket_name" {
  value       = aws_s3_bucket.ml_artifacts.bucket
  description = "Name of the S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.ml_artifacts.arn
  description = "ARN of the S3 bucket"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.ml_artifacts.bucket_domain_name
  description = "Domain name of the S3 bucket"
}



