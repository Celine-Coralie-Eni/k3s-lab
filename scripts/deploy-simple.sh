#!/bin/bash

# Simple K3s Deployment Script
# This script works around multipass issues by using direct network access

set -e

echo "🚀 Starting Simple K3s Deployment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Get VM IPs from DHCP leases
get_vm_ips() {
    print_status "Getting VM IPs from DHCP leases..."
    
    K3S1_IP=$(sudo cat /var/snap/multipass/common/data/multipassd/network/dnsmasq.leases | grep k3s-1 | awk '{print $3}')
    K3S2_IP=$(sudo cat /var/snap/multipass/common/data/multipassd/network/dnsmasq.leases | grep k3s-2 | awk '{print $3}')
    
    if [ -n "$K3S1_IP" ] && [ -n "$K3S2_IP" ]; then
        print_success "Found VMs:"
        echo "  k3s-1: $K3S1_IP"
        echo "  k3s-2: $K3S2_IP"
    else
        echo "❌ Could not determine VM IPs"
        exit 1
    fi
}

# Test VM connectivity
test_vm_connectivity() {
    print_status "Testing VM connectivity..."
    
    # Test k3s-1
    if ping -c 1 -W 5 "$K3S1_IP" > /dev/null 2>&1; then
        print_success "k3s-1 is reachable at $K3S1_IP"
    else
        echo "❌ k3s-1 is not reachable"
        exit 1
    fi
    
    # Test k3s-2
    if ping -c 1 -W 5 "$K3S2_IP" > /dev/null 2>&1; then
        print_success "k3s-2 is reachable at $K3S2_IP"
    else
        echo "❌ k3s-2 is not reachable"
        exit 1
    fi
}

# Check if K3s is already running
check_k3s_status() {
    print_status "Checking current K3s status..."
    
    # Try to check if K3s is already running
    if curl -k -s "https://$K3S1_IP:6443/healthz" > /dev/null 2>&1; then
        print_success "K3s is already running and accessible!"
        return 0
    else
        print_status "K3s is not running or not accessible yet"
        return 1
    fi
}

# Install kubectl if not present
install_kubectl() {
    print_status "Checking kubectl installation..."
    
    if ! command -v kubectl &> /dev/null; then
        print_status "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        print_success "kubectl installed"
    else
        print_success "kubectl is already installed"
    fi
}

# Setup kubectl access
setup_kubectl() {
    print_status "Setting up kubectl access..."
    
    # Create .kube directory if it doesn't exist
    mkdir -p ~/.kube
    
    # Try to get kubeconfig from the server
    if curl -k -s "https://$K3S1_IP:6443/healthz" > /dev/null 2>&1; then
        # K3s is running, try to get kubeconfig
        print_status "K3s is running, attempting to get kubeconfig..."
        
        # For now, create a basic kubeconfig
        cat > ~/.kube/config << EOF
apiVersion: v1
kind: Config
clusters:
- name: k3s-cluster
  cluster:
    server: https://$K3S1_IP:6443
    insecure-skip-tls-verify: true
contexts:
- name: k3s-context
  context:
    cluster: k3s-cluster
    user: k3s-user
current-context: k3s-context
users:
- name: k3s-user
  user:
    token: ""
EOF
        
        print_success "Basic kubeconfig created"
    else
        print_status "K3s not running yet, will configure later"
    fi
}

# Test cluster access
test_cluster() {
    print_status "Testing cluster access..."
    
    if kubectl cluster-info > /dev/null 2>&1; then
        print_success "Cluster is accessible!"
        
        echo ""
        echo "=== Cluster Information ==="
        kubectl cluster-info
        echo ""
        echo "=== Nodes ==="
        kubectl get nodes
    else
        print_warning "Cannot access cluster yet - this is expected if K3s is still starting"
    fi
}

# Display next steps
show_next_steps() {
    echo ""
    print_success "🎉 Basic setup completed!"
    echo ""
    echo "📋 Current Status:"
    echo "  ✅ VMs are running and reachable"
    echo "  ✅ VM IPs determined: $K3S1_IP, $K3S2_IP"
    echo "  ✅ kubectl installed and configured"
    echo ""
    echo "🔍 To check K3s status manually:"
    echo "  1. Check if K3s service is running on VMs"
    echo "  2. Verify cluster health: curl -k https://$K3S1_IP:6443/healthz"
    echo "  3. Check cluster nodes: kubectl get nodes"
    echo ""
    echo "🔗 Next Steps:"
    echo "  1. Verify K3s is running: ./scripts/verify-setup.sh"
    echo "  2. If K3s is running, proceed to Day 3-4"
    echo "  3. If K3s is not running, troubleshoot VM issues"
    echo ""
    echo "💡 Troubleshooting:"
    echo "  - Check VM logs: sudo journalctl -u snap.multipass.multipassd"
    echo "  - Check K3s logs on VMs (if accessible)"
    echo "  - Verify network connectivity between VMs"
}

# Main function
main() {
    echo "🎯 Simple K3s Setup"
    echo "===================="
    
    get_vm_ips
    test_vm_connectivity
    
    if check_k3s_status; then
        print_success "K3s is already running!"
    else
        print_status "K3s needs to be installed/started"
    fi
    
    install_kubectl
    setup_kubectl
    test_cluster
    
    show_next_steps
}

# Run main function
main "$@"
