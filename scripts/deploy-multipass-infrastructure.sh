#!/bin/bash

# Deploy K3s Infrastructure on Multipass VMs
# This script completes Day 1-2 setup for existing Multipass VMs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting Multipass K3s Infrastructure Deployment..."

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

# Verify Multipass VMs
verify_multipass_vms() {
    print_status "Verifying Multipass VMs..."
    
    local vm_count=$(multipass list | grep -c "k3s-")
    local running_vms=$(multipass list | grep "k3s-" | grep -c "Running")
    
    if [ "$vm_count" -ge 2 ] && [ "$running_vms" -ge 2 ]; then
        print_success "Found $vm_count K3s VMs ($running_vms running)"
        
        # Get VM IPs
        local server_ip=$(multipass list | grep "k3s-1" | awk '{print $3}')
        local worker_ip=$(multipass list | grep "k3s-2" | awk '{print $3}')
        
        echo "Server VM (k3s-1): $server_ip"
        echo "Worker VM (k3s-2): $worker_ip"
    else
        print_error "Need at least 2 running K3s VMs"
        exit 1
    fi
}

# Install K3s on server VM
install_k3s_server() {
    print_status "Installing K3s server on k3s-1..."
    
    # Install K3s server
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
    
    # Wait for K3s to be ready
    print_status "Waiting for K3s server to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if multipass exec k3s-1 -- sudo systemctl is-active k3s > /dev/null 2>&1; then
            print_success "K3s server is running!"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for K3s..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "K3s server failed to start"
        exit 1
    fi
    
    # Get join token
    local join_token=$(multipass exec k3s-1 -- sudo cat /var/lib/rancher/k3s/server/node-token)
    echo "$join_token" > /tmp/k3s_join_token
    print_success "K3s server installed and running"
}

# Install K3s agent on worker VM
install_k3s_worker() {
    print_status "Installing K3s agent on k3s-2..."
    
    # Get server IP and join token
    local server_ip=$(multipass list | grep "k3s-1" | awk '{print $3}')
    local join_token=$(cat /tmp/k3s_join_token)
    
    # Install K3s agent
    multipass exec k3s-2 -- bash -c "
        curl -sfL https://get.k3s.io | sh -s - agent \
            --server https://$server_ip:6443 \
            --token $join_token \
            --node-label 'node-role.kubernetes.io/worker=true'
    "
    
    # Wait for agent to join
    print_status "Waiting for K3s agent to join cluster..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; then
        if multipass exec k3s-2 -- test -f /var/lib/rancher/k3s/agent/etc/kubelet.conf; then
            print_success "K3s agent joined successfully!"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts: Waiting for agent..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "K3s agent failed to join"
        exit 1
    fi
    
    print_success "K3s agent installed and joined cluster"
}

# Setup local registry
setup_local_registry() {
    print_status "Setting up local container registry..."
    
    # Install Docker on server VM if not present
    multipass exec k3s-1 -- bash -c "
        if ! command -v docker &> /dev/null; then
            sudo apt update
            sudo apt install -y docker.io
            sudo usermod -aG docker ubuntu
            sudo systemctl enable docker
            sudo systemctl start docker
        fi
    "
    
    # Create registry container
    multipass exec k3s-1 -- bash -c "
        sudo docker run -d \
            --name local-registry \
            --restart=always \
            -p 5000:5000 \
            -v /var/lib/registry:/var/lib/registry \
            registry:2
    "
    
    # Wait for registry to be ready
    print_status "Waiting for registry to be ready..."
    sleep 10
    
    # Test registry
    if multipass exec k3s-1 -- curl -s http://localhost:5000/v2/_catalog > /dev/null 2>&1; then
        print_success "Local registry is running"
    else
        print_error "Local registry failed to start"
        exit 1
    fi
}

# Pre-pull essential images
pre_pull_images() {
    print_status "Pre-pulling essential container images..."
    
    local images=(
        "rancher/klipper-helm:v0.7.9-build20230406"
        "rancher/local-path-provisioner:v0.0.24"
        "rancher/mirrored-coredns-coredns:1.10.1"
        "rancher/mirrored-metrics-server:v0.6.4"
        "ghcr.io/cloudnative-pg/postgresql:15.5"
        "ghcr.io/cloudnative-pg/cloudnative-pg:1.20.1"
        "quay.io/keycloak/keycloak:23.0.3"
        "gitea/gitea:1.21.4"
        "ghcr.io/linkerd/proxy:2.13.4"
        "ghcr.io/linkerd/controller:2.13.4"
        "quay.io/argoproj/argocd:v2.9.3"
        "prom/prometheus:v2.48.0"
        "grafana/grafana:10.2.0"
    )
    
    for image in "${images[@]}"; do
        print_status "Pulling $image..."
        multipass exec k3s-1 -- sudo docker pull "$image"
        
        # Tag for local registry
        local local_name="registry.local:5000/$(echo $image | sed 's|ghcr.io/||' | sed 's|quay.io/||')"
        multipass exec k3s-1 -- sudo docker tag "$image" "$local_name"
        
        # Push to local registry
        multipass exec k3s-1 -- sudo docker push "$local_name"
    done
    
    print_success "All essential images pulled and pushed to local registry"
}

# Configure K3s to use local registry
configure_k3s_registry() {
    print_status "Configuring K3s to use local registry..."
    
    # Create registry config
    multipass exec k3s-1 -- bash -c "
        sudo mkdir -p /etc/rancher/k3s
        sudo tee /etc/rancher/k3s/registries.yaml > /dev/null << 'EOF'
configs:
  'registry.local:5000':
    tls:
      insecure_skip_verify: true
EOF
    "
    
    # Restart K3s to apply config
    multipass exec k3s-1 -- sudo systemctl restart k3s
    
    # Wait for restart
    sleep 20
    
    print_success "K3s configured to use local registry"
}

# Verify cluster
verify_cluster() {
    print_status "Verifying K3s cluster..."
    
    # Copy kubeconfig
    multipass exec k3s-1 -- cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
    
    # Update server IP
    local server_ip=$(multipass list | grep "k3s-1" | awk '{print $3}')
    sed -i "s/127.0.0.1/$server_ip/g" ~/.kube/config
    
    # Check cluster status
    if kubectl cluster-info > /dev/null 2>&1; then
        print_success "Cluster is accessible via kubectl"
        
        echo ""
        print_status "Cluster Information:"
        kubectl cluster-info
        echo ""
        kubectl get nodes
    else
        print_error "Cannot access cluster via kubectl"
        exit 1
    fi
}

# Cleanup temporary files
cleanup() {
    rm -f /tmp/k3s_join_token
}

# Main deployment function
main() {
    echo "🎯 Multipass K3s Infrastructure Deployment"
    echo "=========================================="
    
    # Verify VMs
    verify_multipass_vms
    
    # Install K3s
    install_k3s_server
    install_k3s_worker
    
    # Setup registry
    setup_local_registry
    
    # Pre-pull images
    pre_pull_images
    
    # Configure K3s
    configure_k3s_registry
    
    # Verify cluster
    verify_cluster
    
    # Cleanup
    cleanup
    
    echo ""
    print_success "🎉 Day 1-2 infrastructure deployment completed successfully!"
    echo ""
    echo "📋 What's Now Available:"
    echo "========================="
    echo "✅ K3s cluster with 2 nodes"
    echo "✅ Local container registry at registry.local:5000"
    echo "✅ Essential images pre-pulled"
    echo "✅ kubectl access configured"
    echo ""
    echo "🔗 Next Steps:"
    echo "1. Run: ./scripts/verify-setup.sh (should now pass all checks)"
    echo "2. Deploy core services: ./scripts/deploy-day3-4.sh"
    echo "3. Begin Rust application development"
    echo ""
    echo "💡 Your infrastructure is now ready for Day 3-4!"
}

# Run main function
main "$@"
