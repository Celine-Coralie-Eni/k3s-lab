#!/bin/bash

echo "🔧 Getting K3s kubeconfig file..."

# Get VM IP from DHCP leases
K3S1_IP=$(sudo cat /var/snap/multipass/common/data/multipassd/network/dnsmasq.leases | grep k3s-1 | awk '{print $3}')

echo "K3s server IP: $K3S1_IP"

# Create .kube directory
mkdir -p ~/.kube

# Try to copy kubeconfig using different methods
echo "Attempting to copy kubeconfig..."

# Method 1: Try using scp with default credentials
echo "Method 1: Trying scp..."
if scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@"$K3S1_IP":/etc/rancher/k3s/k3s.yaml ~/.kube/config 2>/dev/null; then
    echo "✅ Successfully copied kubeconfig using scp"
else
    echo "❌ scp failed, trying alternative method..."
    
    # Method 2: Try to access the file directly via the multipass snap
    echo "Method 2: Trying direct file access..."
    if sudo cp /var/snap/multipass/common/data/multipassd/vault/instances/k3s-1/etc/rancher/k3s/k3s.yaml ~/.kube/config 2>/dev/null; then
        echo "✅ Successfully copied kubeconfig using direct file access"
    else
        echo "❌ Direct file access failed"
        echo ""
        echo "🔧 Manual steps needed:"
        echo "1. The kubeconfig file is located at: /etc/rancher/k3s/k3s.yaml on the k3s-1 VM"
        echo "2. You need to copy it manually or fix the multipass command"
        echo "3. Once copied, update the server IP in the kubeconfig file"
        echo ""
        echo "💡 Quick fix: Create a basic kubeconfig manually"
        
        # Create a basic kubeconfig
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
        
        echo "✅ Created basic kubeconfig (may need token)"
        exit 1
    fi
fi

# Update the server IP in the kubeconfig
echo "Updating server IP in kubeconfig..."
sed -i "s/127.0.0.1/$K3S1_IP/g" ~/.kube/config

echo "✅ Kubeconfig setup completed!"
echo "Server IP updated to: $K3S1_IP"

# Test the connection
echo "Testing cluster connection..."
if kubectl cluster-info --request-timeout=10s > /dev/null 2>&1; then
    echo "✅ Cluster connection successful!"
    echo ""
    echo "=== Cluster Information ==="
    kubectl cluster-info
    echo ""
    echo "=== Nodes ==="
    kubectl get nodes
else
    echo "❌ Cluster connection failed"
    echo "You may need to get the authentication token manually"
fi

