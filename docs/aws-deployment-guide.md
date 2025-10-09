# AWS EC2 Deployment Guide

This guide provides comprehensive instructions for setting up automatic deployment of the MLOps drift-aware platform on AWS EC2 using Terraform.

## Architecture Overview

The deployment creates a complete AWS infrastructure including:

- **VPC with Public/Private Subnets**: Multi-AZ setup for high availability
- **EC2 Auto Scaling Group**: Automatically scales based on demand
- **Application Load Balancer**: Distributes traffic and handles SSL termination
- **MSK Kafka Cluster**: Event streaming for real-time data processing
- **RDS PostgreSQL**: Database for Feast offline store and MLflow
- **ElastiCache Redis**: In-memory store for Feast online features
- **S3 Buckets**: ML artifacts and deployment packages storage
- **CodeDeploy**: Automated deployment service
- **CloudWatch**: Monitoring and alerting

## Prerequisites

### 1. AWS Account Setup
- AWS account with appropriate permissions
- AWS CLI configured with credentials
- Terraform >= 1.6.0 installed
- Docker installed (for local testing)

### 2. Required AWS Permissions
Your AWS user/role needs permissions for:
- EC2 (instances, security groups, key pairs)
- VPC (VPCs, subnets, internet gateways, NAT gateways)
- Auto Scaling (launch templates, auto scaling groups)
- Application Load Balancer (load balancers, target groups)
- RDS (database instances, subnet groups)
- ElastiCache (Redis clusters)
- MSK (Kafka clusters)
- S3 (buckets, objects)
- CodeDeploy (applications, deployment groups)
- CloudWatch (alarms, logs)
- IAM (roles, policies)

### 3. GitHub Secrets
Configure the following secrets in your GitHub repository:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

## Quick Start

### 1. Configure Environment Variables

```bash
# Copy the example configuration
cd mlops-drift-platform/infra/terraform
cp env/aws.auto.tfvars.example env/aws.auto.tfvars

# Edit the configuration file
nano env/aws.auto.tfvars
```

Update the following variables in `env/aws.auto.tfvars`:

```hcl
project = "your-project-name"
region  = "us-east-1"
ml_bucket_name = "your-unique-bucket-name"
postgres_password = "your-secure-password" <!-- pragma: allowlist secret -->
environment = "dev"

# Optional: SSL Certificate ARN for HTTPS
# certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file=env/aws.auto.tfvars

# Apply the configuration
terraform apply -var-file=env/aws.auto.tfvars
```

### 3. Deploy Application via GitHub Actions

1. Push your code to the main branch
2. The GitHub Actions workflow will automatically:
   - Deploy infrastructure (if changed)
   - Build Docker images
   - Create deployment packages
   - Deploy to EC2 instances
   - Run smoke tests

### 4. Access Your Application

After deployment, you can access:
- **API**: `https://<load-balancer-dns>/`
- **MLflow**: `https://<load-balancer-dns>/mlflow`
- **Grafana**: `https://<load-balancer-dns>/grafana`

Get the URLs from Terraform outputs:
```bash
terraform output load_balancer_dns_name
terraform output api_url
terraform output mlflow_url
terraform output grafana_url
```

## Manual Deployment

If you prefer manual deployment without GitHub Actions:

### 1. Build and Push Docker Images

```bash
# Build serving image
docker build -t mlops-serving:latest -f services/serving/Dockerfile .

# Tag for ECR (replace with your ECR registry)
docker tag mlops-serving:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/mlops-serving:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/mlops-serving:latest
```

### 2. Create Deployment Package

```bash
# Create deployment directory
mkdir deployment-package
cp -r services deployment-package/
cp -r scripts deployment-package/
cp -r infra/terraform/modules/ec2/deploy/* deployment-package/

# Create ZIP file
cd deployment-package
zip -r ../deployment-package.zip .
cd ..
```

### 3. Deploy via CodeDeploy

```bash
# Get deployment bucket name
DEPLOYMENT_BUCKET=$(terraform output -raw deployment_bucket_name)
CODEDEPLOY_APP=$(terraform output -raw codedeploy_application_name)
CODEDEPLOY_GROUP=$(terraform output -raw codedeploy_deployment_group_name)

# Upload deployment package
aws s3 cp deployment-package.zip s3://$DEPLOYMENT_BUCKET/deployments/$(date +%s).zip

# Create deployment
aws deploy create-deployment \
  --application-name $CODEDEPLOY_APP \
  --deployment-group-name $CODEDEPLOY_GROUP \
  --s3-location bucket=$DEPLOYMENT_BUCKET,key=deployments/$(date +%s).zip,bundleType=zip
```

## Configuration Options

### Instance Types and Scaling

```hcl
# EC2 Configuration
instance_type = "t3.medium"    # Instance type for the platform
min_size = 1                   # Minimum instances
max_size = 5                   # Maximum instances
desired_capacity = 2           # Desired instances

# Database Configuration
postgres_instance_class = "db.t3.micro"  # PostgreSQL instance
redis_node_type = "cache.t3.micro"       # Redis node type
```

### Security Configuration

```hcl
# Enable deletion protection for production
enable_deletion_protection = true
skip_final_snapshot = false

# SSL Certificate (optional)
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id"
```

### Environment-Specific Configurations

Create separate `.tfvars` files for different environments:

```bash
# Development
cp env/aws.auto.tfvars.example env/dev.auto.tfvars

# Production
cp env/aws.auto.tfvars.example env/prod.auto.tfvars
```

Update production settings:
```hcl
environment = "prod"
enable_deletion_protection = true
instance_type = "t3.large"
min_size = 2
max_size = 10
desired_capacity = 3
```

## Monitoring and Alerting

### CloudWatch Alarms

The deployment includes CloudWatch alarms for:
- High CPU utilization (>80%)
- Low CPU utilization (<20%)
- High error rate (>10 errors)
- High latency (>2 seconds)

### Custom Metrics

Your application can send custom metrics to CloudWatch:

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

# Send custom metric
cloudwatch.put_metric_data(
    Namespace='MLOps/Platform',
    MetricData=[
        {
            'MetricName': 'PredictionLatency',
            'Value': latency_ms,
            'Unit': 'Milliseconds',
            'Dimensions': [
                {
                    'Name': 'Service',
                    'Value': 'serving'
                }
            ]
        }
    ]
)
```

### Grafana Dashboards

Access Grafana at `https://<load-balancer-dns>/grafana`:
- Default username: `admin`
- Default password: `admin` <!-- pragma: allowlist secret -->

Pre-configured dashboards include:
- Platform overview
- Inference SLOs
- Drift monitoring
- Auto Scaling metrics

## Troubleshooting

### Common Issues

1. **Deployment Fails**
   - Check CloudWatch logs: `/aws/ec2/mlops-platform`
   - Verify CodeDeploy agent is running: `sudo service codedeploy-agent status`
   - Check security group rules

2. **Services Not Starting**
   - SSH into instance and check Docker: `docker ps`
   - Check application logs: `docker-compose logs`
   - Verify environment variables

3. **Load Balancer Health Checks Failing**
   - Ensure security groups allow traffic from ALB
   - Check application health endpoints
   - Verify target group configuration

### Debugging Commands

```bash
# SSH into EC2 instance
ssh -i your-key.pem ubuntu@<instance-ip>

# Check service status
sudo systemctl status mlops-platform
docker-compose ps
docker-compose logs

# Check CodeDeploy agent
sudo service codedeploy-agent status
sudo tail -f /var/log/aws/codedeploy-agent/codedeploy-agent.log

# Check application logs
tail -f /opt/mlops-platform/logs/*.log
```

### Terraform Debugging

```bash
# Check Terraform state
terraform show
terraform state list

# Import existing resources (if needed)
terraform import aws_instance.example i-1234567890abcdef0

# Refresh state
terraform refresh -var-file=env/aws.auto.tfvars
```

## Cost Optimization

### Development Environment
- Use `t3.micro` instances
- Single AZ deployment
- Minimal database instances
- Estimated cost: $50-100/month

### Production Environment
- Use `t3.large` or larger instances
- Multi-AZ deployment
- Reserved instances for cost savings
- Estimated cost: $300-500/month

### Cost Monitoring
- Set up AWS Budgets
- Use AWS Cost Explorer
- Enable detailed billing reports

## Security Best Practices

1. **Network Security**
   - Use private subnets for application instances
   - Restrict security group rules
   - Enable VPC Flow Logs

2. **Access Control**
   - Use IAM roles instead of access keys
   - Implement least privilege access
   - Enable MFA for console access

3. **Data Protection**
   - Enable encryption at rest and in transit
   - Use AWS KMS for key management
   - Regular security updates

4. **Monitoring**
   - Enable AWS Config
   - Use AWS CloudTrail
   - Set up GuardDuty

## Cleanup

To destroy the infrastructure:

```bash
# Destroy with Terraform
terraform destroy -var-file=env/aws.auto.tfvars

# Manual cleanup (if needed)
# - Delete S3 buckets manually
# - Terminate any remaining instances
# - Clean up CloudWatch logs
```

## Support and Resources

- **AWS Documentation**: [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- **Terraform AWS Provider**: [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- **CodeDeploy Guide**: [AWS CodeDeploy User Guide](https://docs.aws.amazon.com/codedeploy/)
- **Project Issues**: Create an issue in the GitHub repository

## Next Steps

1. **SSL/TLS**: Configure SSL certificates for HTTPS
2. **Custom Domain**: Set up Route 53 for custom domain
3. **Backup Strategy**: Implement automated backups
4. **Disaster Recovery**: Set up multi-region deployment
5. **Performance Tuning**: Optimize based on monitoring data



