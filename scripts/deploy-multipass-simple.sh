#!/bin/bash

# Simple Multipass K3s Deployment
# This script installs K3s on existing Multipass VMs

set -e

echo "🚀 Starting Simple Multipass K3s Deployment..."

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

# Check Multipass VMs
print_status "Checking Multipass VMs..."
multipass list

# Install K3s server on k3s-1
print_status "Installing K3s server on k3s-1..."
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

# Wait for K3s to start
print_status "Waiting for K3s server to start..."
sleep 30

# Get join token
print_status "Getting join token..."
JOIN_TOKEN=$(multipass exec k3s-1 -- sudo cat /var/lib/rancher/k3s/server/node-token)
SERVER_IP=$(multipass list | grep "k3s-1" | awk '{print $3}')

echo "Server IP: $SERVER_IP"
echo "Join Token: $JOIN_TOKEN"

# Install K3s agent on k3s-2
print_status "Installing K3s agent on k3s-2..."
multipass exec k3s-2 -- bash -c "
curl -sfL https://get.k3s.io | sh -s - agent \
  --server https://$SERVER_IP:6443 \
  --token $JOIN_TOKEN \
  --node-label 'node-role.kubernetes.io/worker=true'
"

# Wait for agent to join
print_status "Waiting for agent to join..."
sleep 30

# Setup local registry
print_status "Setting up local registry..."
multipass exec k3s-1 -- bash -c "
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker
"

# Start registry
multipass exec k3s-1 -- bash -c "
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
print_status "Testing registry..."
multipass exec k3s-1 -- curl -s http://localhost:5000/v2/_catalog

# Configure K3s to use local registry
print_status "Configuring K3s to use local registry..."
multipass exec k3s-1 -- bash -c "
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null << 'EOF'
configs:
  'registry.local:5000':
    tls:
      insecure_skip_verify: true
EOF
"

# Restart K3s
print_status "Restarting K3s to apply registry config..."
multipass exec k3s-1 -- sudo systemctl restart k3s
sleep 20

# Copy kubeconfig
print_status "Setting up kubectl access..."
multipass exec k3s-1 -- cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config
sed -i "s/127.0.0.1/$SERVER_IP/g" ~/.kube/config

# Test cluster access
print_status "Testing cluster access..."
kubectl cluster-info
kubectl get nodes

print_success "🎉 K3s deployment completed!"
print_status "Your cluster is ready for Day 3-4 deployment!"
