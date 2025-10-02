#!/bin/bash

# AWS Deployment Setup Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check AWS CLI configuration
check_aws_config() {
    if ! command_exists aws; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi

    print_success "AWS CLI is configured"
}

# Function to check Terraform installation
check_terraform() {
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Please install Terraform >= 1.6.0"
        exit 1
    fi

    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    print_success "Terraform $TERRAFORM_VERSION is installed"
}

# Function to generate secure password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to create configuration file
create_config() {
    local project_name=$1
    local environment=$2
    local region=$3
    local bucket_suffix=$(date +%s)
    
    print_status "Creating configuration file..."
    
    cat > infra/terraform/env/${environment}.auto.tfvars << EOF
project = "${project_name}"
region  = "${region}"
ml_bucket_name = "${project_name}-artifacts-${bucket_suffix}"
enable_gcp = false
environment = "${environment}"

# EC2 Configuration
instance_type = "t3.medium"
min_size = 1
max_size = 5
desired_capacity = 2

# Database Configuration
postgres_password = "$(generate_password)"
postgres_instance_class = "db.t3.micro"
redis_node_type = "cache.t3.micro"

# Security Configuration
enable_deletion_protection = false
skip_final_snapshot = true

# SSL Configuration (optional)
# certificate_arn = "arn:aws:acm:${region}:123456789012:certificate/your-cert-id"
EOF

    print_success "Configuration file created: infra/terraform/env/${environment}.auto.tfvars"
    print_warning "Please save the generated password securely!"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    local environment=$1
    
    print_status "Deploying infrastructure..."
    
    cd infra/terraform
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning deployment..."
    terraform plan -var-file=env/${environment}.auto.tfvars
    
    # Ask for confirmation
    echo -e "${YELLOW}Do you want to proceed with the deployment? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    # Apply configuration
    print_status "Applying Terraform configuration..."
    terraform apply -var-file=env/${environment}.auto.tfvars
    
    print_success "Infrastructure deployed successfully!"
    
    # Display outputs
    print_status "Deployment outputs:"
    echo "Load Balancer DNS: $(terraform output -raw load_balancer_dns_name)"
    echo "API URL: $(terraform output -raw api_url)"
    echo "MLflow URL: $(terraform output -raw mlflow_url)"
    echo "Grafana URL: $(terraform output -raw grafana_url)"
    
    cd ../..
}

# Function to setup GitHub Actions secrets
setup_github_secrets() {
    print_status "Setting up GitHub Actions secrets..."
    
    echo -e "${YELLOW}To enable automated deployments, configure the following secrets in your GitHub repository:${NC}"
    echo "1. Go to your repository settings"
    echo "2. Navigate to Secrets and variables > Actions"
    echo "3. Add the following secrets:"
    echo "   - AWS_ACCESS_KEY_ID: Your AWS access key"
    echo "   - AWS_SECRET_ACCESS_KEY: Your AWS secret key"
    echo ""
    echo -e "${BLUE}You can get these credentials from:${NC}"
    echo "aws configure list"
}

# Function to run smoke tests
run_smoke_tests() {
    local api_url=$1
    
    print_status "Running smoke tests..."
    
    # Wait for services to be ready
    print_status "Waiting for services to start..."
    sleep 60
    
    # Test health endpoint
    if curl -f "${api_url}/health" >/dev/null 2>&1; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
        return 1
    fi
    
    # Test prediction endpoint
    local response
    response=$(curl -s -X POST "${api_url}/predict" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "test-user",
            "event": {
                "transaction_amount": 100.0,
                "country": "US",
                "device": "web",
                "event_ts": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
            }
        }')
    
    if echo "$response" | grep -q "prediction"; then
        print_success "Prediction endpoint working"
    else
        print_error "Prediction endpoint failed"
        echo "Response: $response"
        return 1
    fi
    
    print_success "All smoke tests passed!"
}

# Main function
main() {
    echo -e "${BLUE}MLOps Platform AWS Deployment Setup${NC}"
    echo "=================================="
    echo ""
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    check_aws_config
    check_terraform
    
    # Get user input
    echo -e "${YELLOW}Enter project configuration:${NC}"
    read -p "Project name (e.g., mlops-demo): " PROJECT_NAME
    read -p "Environment (dev/staging/prod): " ENVIRONMENT
    read -p "AWS Region (e.g., us-east-1): " REGION
    
    # Validate inputs
    if [[ -z "$PROJECT_NAME" || -z "$ENVIRONMENT" || -z "$REGION" ]]; then
        print_error "All fields are required"
        exit 1
    fi
    
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Environment must be dev, staging, or prod"
        exit 1
    fi
    
    # Create configuration
    create_config "$PROJECT_NAME" "$ENVIRONMENT" "$REGION"
    
    # Deploy infrastructure
    deploy_infrastructure "$ENVIRONMENT"
    
    # Setup GitHub Actions
    setup_github_secrets
    
    # Run smoke tests
    cd infra/terraform
    API_URL=$(terraform output -raw api_url)
    cd ../..
    
    if run_smoke_tests "$API_URL"; then
        print_success "Deployment completed successfully!"
        echo ""
        echo -e "${GREEN}Your MLOps platform is now running at:${NC}"
        echo "API: $API_URL"
        echo "MLflow: $(cd infra/terraform && terraform output -raw mlflow_url)"
        echo "Grafana: $(cd infra/terraform && terraform output -raw grafana_url)"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Configure GitHub Actions secrets for automated deployments"
        echo "2. Set up SSL certificates for HTTPS"
        echo "3. Configure custom domain (optional)"
        echo "4. Review and adjust monitoring alerts"
    else
        print_error "Smoke tests failed. Please check the logs and troubleshoot."
        exit 1
    fi
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --config   Create configuration file only"
    echo "  -d, --deploy   Deploy infrastructure only"
    echo "  -t, --test     Run smoke tests only"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive setup"
    echo "  $0 --config          # Create config file only"
    echo "  $0 --deploy dev      # Deploy dev environment"
    echo "  $0 --test https://api.example.com  # Test API endpoint"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -c|--config)
        read -p "Project name: " PROJECT_NAME
        read -p "Environment: " ENVIRONMENT
        read -p "Region: " REGION
        create_config "$PROJECT_NAME" "$ENVIRONMENT" "$REGION"
        exit 0
        ;;
    -d|--deploy)
        ENVIRONMENT=${2:-dev}
        deploy_infrastructure "$ENVIRONMENT"
        exit 0
        ;;
    -t|--test)
        API_URL=${2:-}
        if [[ -z "$API_URL" ]]; then
            print_error "API URL is required for testing"
            exit 1
        fi
        run_smoke_tests "$API_URL"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac



