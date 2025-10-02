# EC2 Instance Module for MLOps Platform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }
}

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# Security Group for MLOps Platform
resource "aws_security_group" "mlops_platform" {
  name_prefix = "${var.project}-mlops-platform-"
  vpc_id      = var.vpc_id

  # HTTP/HTTPS for API access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ray Serve API
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # MLflow
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Prometheus
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Grafana
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH access (restrict to VPC)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-mlops-platform-sg"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "mlops_instance_role" {
  name = "${var.project}-mlops-instance-role"

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
    Name = "${var.project}-mlops-instance-role"
  }
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "mlops_s3_policy" {
  name = "${var.project}-mlops-s3-policy"
  role = aws_iam_role.mlops_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.ml_bucket_name}",
          "arn:aws:s3:::${var.ml_bucket_name}/*"
        ]
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "mlops_cloudwatch_policy" {
  name = "${var.project}-mlops-cloudwatch-policy"
  role = aws_iam_role.mlops_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for Secrets Manager (for database credentials)
resource "aws_iam_role_policy" "mlops_secrets_policy" {
  name = "${var.project}-mlops-secrets-policy"
  role = aws_iam_role.mlops_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:*:secret:${var.project}-*"
        ]
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "mlops_instance_profile" {
  name = "${var.project}-mlops-instance-profile"
  role = aws_iam_role.mlops_instance_role.name

  tags = {
    Name = "${var.project}-mlops-instance-profile"
  }
}

# Launch Template
resource "aws_launch_template" "mlops_platform" {
  name_prefix   = "${var.project}-mlops-platform-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.mlops_platform.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.mlops_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name     = var.project
    ml_bucket_name   = var.ml_bucket_name
    region           = var.region
    kafka_brokers    = var.kafka_bootstrap_servers
    redis_endpoint   = var.redis_endpoint
    postgres_endpoint = var.postgres_endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-mlops-platform"
    }
  }

  tags = {
    Name = "${var.project}-mlops-platform-template"
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "mlops_platform" {
  name                = "${var.project}-mlops-platform-asg"
  vpc_zone_identifier = data.aws_subnets.private.ids
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.mlops_platform.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-mlops-platform"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project}-mlops-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.mlops_platform.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project}-mlops-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.mlops_platform.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-mlops-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.mlops_platform.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project}-mlops-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.mlops_platform.name
  }
}

