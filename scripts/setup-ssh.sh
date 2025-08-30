#!/bin/bash

# Setup SSH keys for K3s Lab
# This script generates SSH keys and sets up proper permissions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SSH_DIR="$PROJECT_DIR/ansible/ssh"

echo "🔑 Setting up SSH keys for K3s Lab..."

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_DIR"

# Check if SSH key already exists
if [ -f "$SSH_DIR/id_rsa" ] && [ -f "$SSH_DIR/id_rsa.pub" ]; then
    echo "✅ SSH keys already exist in $SSH_DIR"
    echo "Public key:"
    cat "$SSH_DIR/id_rsa.pub"
    exit 0
fi

# Generate new SSH key pair
echo "📝 Generating new SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N "" -C "k3s-lab@$(hostname)"

# Set proper permissions
chmod 600 "$SSH_DIR/id_rsa"
chmod 644 "$SSH_DIR/id_rsa.pub"

echo "✅ SSH keys generated successfully!"
echo ""
echo "🔐 Private key: $SSH_DIR/id_rsa"
echo "🔓 Public key: $SSH_DIR/id_rsa.pub"
echo ""
echo "📋 Public key content:"
cat "$SSH_DIR/id_rsa.pub"
echo ""
echo "💡 Next steps:"
echo "1. Copy the public key above to your VMs if needed"
echo "2. Run: chmod 600 $SSH_DIR/id_rsa"
echo "3. Test connection: ssh -i $SSH_DIR/id_rsa ubuntu@<VM_IP>"


