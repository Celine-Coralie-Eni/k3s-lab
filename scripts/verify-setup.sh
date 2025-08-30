#!/bin/bash

# Verify Day 1-2 Setup
# This script checks that all infrastructure components are working

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔍 Verifying Day 1-2 Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if SSH keys exist
check_ssh_keys() {
    print_status "Checking SSH keys..."
    if [ -f "$PROJECT_DIR/ansible/ssh/id_rsa" ] && [ -f "$PROJECT_DIR/ansible/ssh/id_rsa.pub" ]; then
        print_success "SSH keys found"
    else
        print_error "SSH keys missing. Run: ./scripts/setup-ssh.sh"
        exit 1
    fi
}

# Check VM status
check_vms() {
    print_status "Checking VM status..."
    if command -v virsh &> /dev/null; then
        local vm_count=$(virsh list --all | grep -c "k3s-")
        if [ "$vm_count" -ge 2 ]; then
            print_success "Found $vm_count K3s VMs"
        else
            print_error "Expected at least 2 K3s VMs, found $vm_count"
            exit 1
        fi
    else
        print_warning "virsh not found - skipping VM check"
    fi
}

# Check K3s cluster
check_k3s() {
    print_status "Checking K3s cluster..."
    
    # Get server IP from Terraform output
    cd "$PROJECT_DIR/terraform"
    if [ -f "terraform.tfstate" ]; then
        local server_ip=$(terraform output -raw k3s_server_ip 2>/dev/null || echo "")
        if [ -n "$server_ip" ]; then
            print_status "K3s server IP: $server_ip"
            
            # Test SSH connection
            if ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@"$server_ip" "echo 'SSH OK'" 2>/dev/null; then
                print_success "SSH connection to K3s server successful"
                
                # Check K3s status
                local k3s_status=$(ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" ubuntu@"$server_ip" "sudo systemctl is-active k3s" 2>/dev/null)
                if [ "$k3s_status" = "active" ]; then
                    print_success "K3s service is running"
                    
                    # Check cluster nodes
                    local node_count=$(ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" ubuntu@"$server_ip" "sudo kubectl get nodes --no-headers | wc -l" 2>/dev/null)
                    if [ "$node_count" -ge 2 ]; then
                        print_success "K3s cluster has $node_count nodes"
                    else
                        print_warning "K3s cluster has only $node_count nodes (expected 2+)"
                    fi
                else
                    print_error "K3s service is not running"
                    exit 1
                fi
            else
                print_error "SSH connection to K3s server failed"
                exit 1
            fi
        else
            print_error "Could not get K3s server IP from Terraform"
            exit 1
        fi
    else
        print_error "Terraform state file not found"
        exit 1
    fi
}

# Check local registry
check_registry() {
    print_status "Checking local registry..."
    
    # Try to connect to registry
    if curl -s http://registry.local:5000/v2/_catalog > /dev/null 2>&1; then
        print_success "Local registry is accessible"
        
        # Check for essential images
        local image_count=$(curl -s http://registry.local:5000/v2/_catalog | jq '.repositories | length' 2>/dev/null || echo "0")
        if [ "$image_count" -gt 0 ]; then
            print_success "Registry contains $image_count image repositories"
        else
            print_warning "Registry appears empty"
        fi
    else
        print_warning "Local registry not accessible - may need to be set up"
    fi
}

# Check kubectl access
check_kubectl() {
    print_status "Checking kubectl access..."
    
    if command -v kubectl &> /dev/null; then
        # Copy kubeconfig if not exists
        if [ ! -f ~/.kube/config ]; then
            cd "$PROJECT_DIR/terraform"
            local server_ip=$(terraform output -raw k3s_server_ip 2>/dev/null || echo "")
            if [ -n "$server_ip" ]; then
                scp -i "$PROJECT_DIR/ansible/ssh/id_rsa" ubuntu@"$server_ip":/etc/rancher/k3s/k3s.yaml ~/.kube/config
                sed -i "s/127.0.0.1/$server_ip/g" ~/.kube/config
                print_success "Kubeconfig copied and configured"
            fi
        fi
        
        # Test kubectl
        if kubectl cluster-info > /dev/null 2>&1; then
            print_success "kubectl can access the cluster"
            
            # Show cluster info
            echo ""
            print_status "Cluster Information:"
            kubectl cluster-info
            echo ""
            kubectl get nodes
        else
            print_error "kubectl cannot access the cluster"
        fi
    else
        print_warning "kubectl not installed"
    fi
}

# Main verification
main() {
    echo "🎯 Day 1-2 Setup Verification"
    echo "=============================="
    
    check_ssh_keys
    check_vms
    check_k3s
    check_registry
    check_kubectl
    
    echo ""
    print_success "🎉 Day 1-2 setup verification completed!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Deploy PostgreSQL (CloudNativePG)"
    echo "2. Install Keycloak for authentication"
    echo "3. Set up Gitea for Git repository management"
    echo "4. Begin Rust application development"
    echo ""
    echo "💡 Ready to proceed with Day 3-4!"
}

main "$@"
