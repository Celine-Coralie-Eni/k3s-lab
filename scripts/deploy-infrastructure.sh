#!/bin/bash

# Deploy K3s Infrastructure
# This script automates the Day 1-2 setup process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting K3s Infrastructure Deployment..."
echo "📍 Project directory: $PROJECT_DIR"

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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if required tools are installed
    local tools=("terraform" "ansible" "docker" "virsh")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install the missing tools and try again."
        exit 1
    fi
    
    print_success "All prerequisites are satisfied!"
}

# Setup SSH keys
setup_ssh() {
    print_status "Setting up SSH keys..."
    
    if [ ! -f "$PROJECT_DIR/ansible/ssh/id_rsa" ]; then
        print_status "Generating SSH keys..."
        bash "$SCRIPT_DIR/setup-ssh.sh"
    else
        print_success "SSH keys already exist"
    fi
}

# Deploy infrastructure with Terraform
deploy_terraform() {
    print_status "Deploying infrastructure with Terraform..."
    
    cd "$PROJECT_DIR/terraform"
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    print_status "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Get outputs
    print_status "Getting deployment outputs..."
    terraform output
    
    print_success "Terraform deployment completed!"
}

# Wait for VMs to be ready
wait_for_vms() {
    print_status "Waiting for VMs to be ready..."
    
    # Get VM IPs from Terraform output
    cd "$PROJECT_DIR/terraform"
    local server_ip=$(terraform output -raw k3s_server_ip)
    
    print_status "Waiting for K3s server at $server_ip..."
    
    # Wait for SSH access
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@"$server_ip" "echo 'SSH connection successful'" 2>/dev/null; then
            print_success "SSH access to K3s server established!"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for SSH access..."
        sleep 30
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Failed to establish SSH connection after $max_attempts attempts"
        exit 1
    fi
}

# Configure K3s with Ansible
configure_k3s() {
    print_status "Configuring K3s with Ansible..."
    
    cd "$PROJECT_DIR/ansible"
    
    # Test Ansible connectivity
    print_status "Testing Ansible connectivity..."
    ansible all -m ping -i inventory
    
    # Run K3s setup
    print_status "Running K3s setup playbook..."
    ansible-playbook -i inventory k3s-setup.yml
    
    print_success "K3s configuration completed!"
}

# Setup local registry
setup_registry() {
    print_status "Setting up local container registry..."
    
    cd "$PROJECT_DIR/ansible"
    
    # Run registry setup
    ansible-playbook -i inventory registry-setup.yml
    
    print_success "Local registry setup completed!"
}

# Pre-pull images
pre_pull_images() {
    print_status "Pre-pulling essential container images..."
    
    cd "$PROJECT_DIR/ansible"
    
    # Run image pre-pulling
    ansible-playbook -i inventory pre-pull-images.yml
    
    print_success "Image pre-pulling completed!"
}

# Main deployment function
main() {
    echo "🎯 K3s Lab - Day 1-2 Infrastructure Deployment"
    echo "================================================"
    
    # Check prerequisites
    check_prerequisites
    
    # Setup SSH keys
    setup_ssh
    
    # Deploy infrastructure
    deploy_terraform
    
    # Wait for VMs
    wait_for_vms
    
    # Configure K3s
    configure_k3s
    
    # Setup registry
    setup_registry
    
    # Pre-pull images
    pre_pull_images
    
    echo ""
    print_success "🎉 Infrastructure deployment completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Verify cluster status: kubectl get nodes"
    echo "2. Deploy core services (Day 3-4)"
    echo "3. Develop and deploy your Rust application"
    echo ""
    echo "🔗 Useful commands:"
    echo "- Check cluster: kubectl cluster-info"
    echo "- View nodes: kubectl get nodes"
    echo "- Check pods: kubectl get pods --all-namespaces"
    echo "- Registry status: curl http://registry.local:5000/v2/_catalog"
}

# Run main function
main "$@"


