#!/bin/bash

echo "🔐 Getting K3s Cluster Credentials..."

# Get VM IP from DHCP leases
K3S1_IP=$(sudo cat /var/snap/multipass/common/data/multipassd/network/dnsmasq.leases | grep k3s-1 | awk '{print $3}')

echo "K3s server IP: $K3S1_IP"

# Method 1: Try to get the token from the VM filesystem
echo "🔍 Looking for K3s token in VM filesystem..."

# Check if we can access the token file directly
TOKEN_FILE="/var/snap/multipass/common/data/multipassd/vault/instances/k3s-1/var/lib/rancher/k3s/server/node-token"

if [ -f "$TOKEN_FILE" ]; then
    echo "✅ Found token file!"
    TOKEN=$(sudo cat "$TOKEN_FILE")
    echo "Token: $TOKEN"
else
    echo "❌ Token file not found at expected location"
    echo "🔍 Searching for token in other locations..."
    
    # Try alternative locations
    ALTERNATIVE_LOCATIONS=(
        "/var/snap/multipass/common/data/multipassd/vault/instances/k3s-1/etc/rancher/k3s/node-token"
        "/var/snap/multipass/common/data/multipassd/vault/instances/k3s-1/var/lib/rancher/k3s/agent/node-token"
    )
    
    for location in "${ALTERNATIVE_LOCATIONS[@]}"; do
        if [ -f "$location" ]; then
            echo "✅ Found token at: $location"
            TOKEN=$(sudo cat "$location")
            echo "Token: $TOKEN"
            break
        fi
    done
fi

# Method 2: Try to get the kubeconfig file
echo ""
echo "📄 Looking for kubeconfig file..."

KUBECONFIG_FILE="/var/snap/multipass/common/data/multipassd/vault/instances/k3s-1/etc/rancher/k3s/k3s.yaml"

if [ -f "$KUBECONFIG_FILE" ]; then
    echo "✅ Found kubeconfig file!"
    
    # Create .kube directory
    mkdir -p ~/.kube
    
    # Copy the kubeconfig
    sudo cp "$KUBECONFIG_FILE" ~/.kube/config
    
    # Update the server IP
    sed -i "s/127.0.0.1/$K3S1_IP/g" ~/.kube/config
    
    echo "✅ Kubeconfig copied and updated!"
    echo "Server IP updated to: $K3S1_IP"
    
    # Show the kubeconfig content (without sensitive data)
    echo ""
    echo "📋 Kubeconfig content:"
    cat ~/.kube/config | grep -v "certificate-authority-data\|client-certificate-data\|client-key-data"
    
else
    echo "❌ Kubeconfig file not found"
fi

# Method 3: Try to get credentials from running processes
echo ""
echo "🔍 Checking for running K3s processes..."

# Look for K3s processes and their config
if pgrep -f "k3s server" > /dev/null; then
    echo "✅ K3s server process is running"
    
    # Try to get the data directory
    K3S_DATA_DIR=$(sudo find /var/snap/multipass/common/data/multipassd/vault/instances/k3s-1 -name "k3s" -type d 2>/dev/null | head -1)
    
    if [ -n "$K3S_DATA_DIR" ]; then
        echo "Found K3s data directory: $K3S_DATA_DIR"
        
        # Look for token in the data directory
        TOKEN_FILES=$(sudo find "$K3S_DATA_DIR" -name "*token*" 2>/dev/null)
        if [ -n "$TOKEN_FILES" ]; then
            echo "Found token files:"
            echo "$TOKEN_FILES"
        fi
    fi
fi

echo ""
echo "=== Summary ==="
if [ -f ~/.kube/config ]; then
    echo "✅ Kubeconfig file: ~/.kube/config"
    echo "✅ Server IP: $K3S1_IP"
    
    if [ -n "$TOKEN" ]; then
        echo "✅ Token found: $TOKEN"
    else
        echo "⚠️  Token not found automatically"
    fi
    
    echo ""
    echo "🧪 Testing cluster access..."
    if kubectl cluster-info --request-timeout=10s > /dev/null 2>&1; then
        echo "✅ Cluster access successful!"
        echo ""
        echo "=== Cluster Information ==="
        kubectl cluster-info
        echo ""
        echo "=== Nodes ==="
        kubectl get nodes
    else
        echo "❌ Cluster access failed"
        echo ""
        echo "🔧 Manual steps to fix:"
        echo "1. SSH into the VM: ssh ubuntu@$K3S1_IP"
        echo "2. Get the token: sudo cat /var/lib/rancher/k3s/server/node-token"
        echo "3. Update your kubeconfig with the token"
    fi
else
    echo "❌ Could not retrieve credentials automatically"
    echo ""
    echo "🔧 Manual steps:"
    echo "1. SSH into the VM: ssh ubuntu@$K3S1_IP"
    echo "2. Copy kubeconfig: sudo cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml"
    echo "3. Copy to your machine and update the server IP"
fi

