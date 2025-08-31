#!/bin/bash

# Fixed Multipass K3s Deployment
# This script uses multipass exec to work with the VMs

set -e

echo "🚀 Starting Fixed Multipass K3s Deployment..."

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

# Check if multipass command works
check_multipass() {
    print_status "Checking multipass command..."
    
    if ! command -v multipass &> /dev/null; then
        echo "❌ multipass command not found"
        exit 1
    fi
    
    # Try to list VMs
    if multipass list 2>&1 | grep -q "k3s"; then
        print_success "multipass command is working"
    else
        echo "⚠️  multipass list not working, but continuing..."
    fi
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

# Install K3s on server VM (k3s-1)
install_k3s_server() {
    print_status "Installing K3s server on k3s-1..."
    
    # Use multipass exec to install K3s
    multipass exec k3s-1 -- bash -c "
        curl -sfL https://get.k3s.io | sh -s - server \
            --write-kubeconfig-mode 644 \
            --disable traefik \
            --disable servicelb \
            --disable-cloud-controller \
            --disable-network-policy \
            --disable-helm-controller \
            --disable local-storage \
            --node-label 'node-role.kubernetes.io/server=true' \
            --node-label 'node-role.kubernetes.io/control-plane=true'
    "
    
    print_success "K3s server installation completed"
}

# Wait for K3s server to be ready
wait_for_k3s_server() {
    print_status "Waiting for K3s server to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if multipass exec k3s-1 -- sudo systemctl is-active k3s 2>/dev/null | grep -q "active"; then
            print_success "K3s server is running!"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for K3s..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ K3s server failed to start"
        exit 1
    fi
}

# Get join token
get_join_token() {
    print_status "Getting join token..."
    
    JOIN_TOKEN=$(multipass exec k3s-1 -- sudo cat /var/lib/rancher/k3s/server/node-token)
    
    if [ -n "$JOIN_TOKEN" ]; then
        print_success "Join token obtained"
        echo "Token: $JOIN_TOKEN"
    else
        echo "❌ Could not get join token"
        exit 1
    fi
}

# Install K3s agent on worker VM (k3s-2)
install_k3s_worker() {
    print_status "Installing K3s agent on k3s-2..."
    
    multipass exec k3s-2 -- bash -c "
        curl -sfL https://get.k3s.io | sh -s - agent \
            --server https://$K3S1_IP:6443 \
            --token $JOIN_TOKEN \
            --node-label 'node-role.kubernetes.io/worker=true'
    "
    
    print_success "K3s agent installation completed"
}

# Wait for worker to join
wait_for_worker() {
    print_status "Waiting for worker to join cluster..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if multipass exec k3s-2 -- test -f /var/lib/rancher/k3s/agent/etc/kubelet.conf 2>/dev/null; then
            print_success "Worker joined successfully!"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for worker..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "❌ Worker failed to join"
        exit 1
    fi
}

# Setup local registry
setup_registry() {
    print_status "Setting up local registry on k3s-1..."
    
    multipass exec k3s-1 -- bash -c "
        sudo apt update
        sudo apt install -y docker.io
        sudo usermod -aG docker ubuntu
        sudo systemctl enable docker
        sudo systemctl start docker
        
        sudo docker run -d \
            --name local-registry \
            --restart=always \
            -p 5000:5000 \
            -v /var/lib/registry:/var/lib/registry \
            registry:2
    "
    
    # Wait for registry
    sleep 10
    
    # Test registry
    if multipass exec k3s-1 -- curl -s http://localhost:5000/v2/_catalog 2>/dev/null; then
        print_success "Local registry is running"
    else
        echo "❌ Registry failed to start"
        exit 1
    fi
}

# Configure K3s to use local registry
configure_registry() {
    print_status "Configuring K3s to use local registry..."
    
    multipass exec k3s-1 -- bash -c "
        sudo mkdir -p /etc/rancher/k3s
        sudo tee /etc/rancher/k3s/registries.yaml > /dev/null << 'EOF'
configs:
  'registry.local:5000':
    tls:
      insecure_skip_verify: true
EOF
        
        sudo systemctl restart k3s
    "
    
    # Wait for restart
    sleep 20
    print_success "K3s configured to use local registry"
}

# Setup kubectl access
setup_kubectl() {
    print_status "Setting up kubectl access..."
    
    # Copy kubeconfig
    multipass exec k3s-1 -- cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
    
    # Update server IP
    sed -i "s/127.0.0.1/$K3S1_IP/g" ~/.kube/config
    
    print_success "kubectl configured"
}

# Test cluster
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
        echo "❌ Cannot access cluster"
        exit 1
    fi
}

# Main deployment
main() {
    echo "🎯 Fixed Multipass K3s Deployment"
    echo "=================================="
    
    check_multipass
    get_vm_ips
    test_vm_connectivity
    
    install_k3s_server
    wait_for_k3s_server
    
    get_join_token
    install_k3s_worker
    wait_for_worker
    
    setup_registry
    configure_registry
    
    setup_kubectl
    test_cluster
    
    echo ""
    print_success "🎉 K3s deployment completed successfully!"
    echo ""
    echo "📋 Cluster Information:"
    echo "  Server: $K3S1_IP"
    echo "  Worker: $K3S2_IP"
    echo "  Registry: registry.local:5000"
    echo ""
    echo "🔗 Next Steps:"
    echo "1. Run: ./scripts/verify-setup.sh"
    echo "2. Deploy core services: ./scripts/deploy-day3-4.sh"
    echo "3. Begin Rust application development"
}

# Run main function
main "$@"
