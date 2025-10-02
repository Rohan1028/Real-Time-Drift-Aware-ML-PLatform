#!/bin/bash

# MLOps Platform EC2 User Data Script
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Python 3.11 and Poetry
apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip
curl -sSL https://install.python-poetry.org | python3.11 -

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create application directory
mkdir -p /opt/mlops-platform
cd /opt/mlops-platform

# Create environment file
cat > .env << EOF
# AWS Configuration
AWS_REGION=${region}
PROJECT_NAME=${project_name}
ML_BUCKET_NAME=${ml_bucket_name}

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=${kafka_brokers}

# Database Configuration
REDIS_ENDPOINT=${redis_endpoint}
POSTGRES_ENDPOINT=${postgres_endpoint}

# MLflow Configuration
MLFLOW_TRACKING_URI=http://localhost:5000
MLFLOW_S3_ENDPOINT_URL=https://s3.${region}.amazonaws.com

# Ray Configuration
RAY_HEAD_HOST=0.0.0.0
RAY_HEAD_PORT=10001

# Monitoring
ENABLE_METRICS=true
ENABLE_TRACING=true
EOF

# Clone the repository (you'll need to set up proper access)
# For now, we'll create a placeholder structure
mkdir -p services/{common,serving,monitoring}

# Create a simple startup script
cat > /opt/mlops-platform/start_services.sh << 'EOF'
#!/bin/bash
set -e

cd /opt/mlops-platform

# Start monitoring services first
docker-compose up -d prometheus grafana

# Wait for dependencies
sleep 30

# Start MLflow
docker-compose up -d mlflow

# Start the serving application
docker-compose up -d serving

# Start drift monitoring
docker-compose up -d drift-monitor

echo "All services started successfully"
EOF

chmod +x /opt/mlops-platform/start_services.sh

# Create systemd service for auto-start
cat > /etc/systemd/system/mlops-platform.service << EOF
[Unit]
Description=MLOps Platform Services
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mlops-platform
ExecStart=/opt/mlops-platform/start_services.sh
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable mlops-platform.service

# Create CloudWatch config for application logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/opt/mlops-platform/logs/*.log",
                        "log_group_name": "/aws/ec2/mlops-platform",
                        "log_stream_name": "{instance_id}",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "MLOps/Platform",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create deployment script for CodeDeploy
mkdir -p /opt/mlops-platform/deploy
cat > /opt/mlops-platform/deploy/install.sh << 'EOF'
#!/bin/bash
set -e

cd /opt/mlops-platform

# Stop existing services
docker-compose down || true

# Pull latest changes (this would be handled by CodeDeploy)
# git pull origin main

# Install/update dependencies
poetry install --no-dev

# Start services
./start_services.sh

echo "Deployment completed successfully"
EOF

chmod +x /opt/mlops-platform/deploy/install.sh

# Log completion
echo "User data script completed at $(date)" >> /var/log/user-data.log

