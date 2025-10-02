#!/bin/bash

# Install CodeDeploy Agent on Ubuntu
set -e

# Update system
apt-get update
apt-get install -y ruby wget

# Download and install CodeDeploy agent
cd /home/ubuntu
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
./install auto

# Enable and start the service
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# Verify installation
service codedeploy-agent status

echo "CodeDeploy agent installed successfully"



