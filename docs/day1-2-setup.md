# Day 1-2: Infrastructure Setup Guide

## Overview

This guide covers the first two days of your K3s lab assignment, focusing on setting up the foundational infrastructure including VMs, K3s cluster, and offline preparation.

## Prerequisites

Before starting, ensure you have the following installed on your local machine:

- **Terraform** (>= 1.0)
- **Ansible** (>= 2.12)
- **Docker** (>= 20.10)
- **Libvirt** with QEMU/KVM
- **Vagrant** or **Multipass** (if not using libvirt directly)

## Step-by-Step Setup

### Step 1: Prepare Your Environment

1. **Clone or create your project directory:**
   ```bash
   mkdir k3s-lab
   cd k3s-lab
   ```

2. **Install required tools:**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install -y terraform ansible docker.io libvirt-daemon-system libvirt-clients qemu-kvm
   
   # Or use the provided scripts
   chmod +x scripts/setup-ssh.sh
   chmod +x scripts/deploy-infrastructure.sh
   ```

### Step 2: Configure SSH Keys

1. **Generate SSH keys for VM access:**
   ```bash
   ./scripts/setup-ssh.sh
   ```

2. **Verify SSH key setup:**
   ```bash
   ls -la ansible/ssh/
   # Should show: id_rsa (private) and id_rsa.pub (public)
   ```

### Step 3: Prepare Base Images

1. **Download Ubuntu cloud image:**
   ```bash
   sudo mkdir -p /var/lib/libvirt/images
   cd /var/lib/libvirt/images
   sudo wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
   ```

2. **Verify image:**
   ```bash
   ls -la ubuntu-22.04-server-cloudimg-amd64.img
   ```

### Step 4: Configure Terraform

1. **Copy and customize variables:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferences
   ```

2. **Review configuration:**
   ```bash
   terraform init
   terraform plan
   ```

### Step 5: Deploy Infrastructure

1. **Run the automated deployment:**
   ```bash
   cd ..
   ./scripts/deploy-infrastructure.sh
   ```

   This script will:
   - Check prerequisites
   - Set up SSH keys
   - Deploy VMs with Terraform
   - Wait for VMs to be ready
   - Configure K3s cluster
   - Set up local registry
   - Pre-pull essential images

2. **Monitor the deployment:**
   ```bash
   # Check VM status
   virsh list --all
   
   # Check K3s status
   ssh -i ansible/ssh/id_rsa ubuntu@<SERVER_IP> "sudo systemctl status k3s"
   
   # Check registry status
   curl http://registry.local:5000/v2/_catalog
   ```

### Step 6: Verify K3s Cluster

1. **Access the cluster:**
   ```bash
   # Copy kubeconfig to local machine
   scp -i ansible/ssh/id_rsa ubuntu@<SERVER_IP>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
   
   # Update server IP in kubeconfig
   sed -i "s/127.0.0.1/<SERVER_IP>/g" ~/.kube/config
   ```

2. **Verify cluster status:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

### Step 7: Test Offline Capabilities

1. **Verify local registry:**
   ```bash
   # List available images
   curl http://registry.local:5000/v2/_catalog
   
   # Test pulling an image
   docker pull registry.local:5000/rancher/klipper-helm:v0.7.9-build20230406
   ```

2. **Test K3s offline functionality:**
   ```bash
   # Create a test pod using local registry
   kubectl run test-nginx --image=registry.local:5000/nginx:latest
   kubectl get pods
   ```

## Manual Steps (if automated script fails)

### Manual VM Creation

If you prefer to create VMs manually:

1. **Create VMs with Vagrant:**
   ```bash
   # Create Vagrantfile
   vagrant init ubuntu/jammy64
   
   # Edit Vagrantfile for your needs
   # Start VMs
   vagrant up
   ```

2. **Or with Multipass:**
   ```bash
   multipass launch --name k3s-server --memory 4G --disk 20G
   multipass launch --name k3s-worker --memory 4G --disk 20G
   ```

### Manual K3s Installation

1. **On server node:**
   ```bash
   curl -sfL https://get.k3s.io | sh -s - server \
     --write-kubeconfig-mode 644 \
     --disable traefik \
     --disable servicelb
   ```

2. **Get join token:**
   ```bash
   sudo cat /var/lib/rancher/k3s/server/node-token
   ```

3. **On worker nodes:**
   ```bash
   curl -sfL https://get.k3s.io | sh -s - agent \
     --server https://<SERVER_IP>:6443 \
     --token <JOIN_TOKEN>
   ```

## Troubleshooting

### Common Issues

1. **VMs not starting:**
   ```bash
   # Check libvirt status
   sudo systemctl status libvirtd
   
   # Check VM logs
   virsh console <VM_NAME>
   ```

2. **SSH connection failed:**
   ```bash
   # Check VM IP
   virsh domifaddr <VM_NAME>
   
   # Check SSH service
   ssh -i ansible/ssh/id_rsa ubuntu@<VM_IP> "sudo systemctl status ssh"
   ```

3. **K3s not starting:**
   ```bash
   # Check K3s logs
   sudo journalctl -u k3s -f
   
   # Check system resources
   free -h
   df -h
   ```

4. **Registry not accessible:**
   ```bash
   # Check registry container
   docker ps | grep registry
   
   # Check registry logs
   docker logs local-registry
   ```

### Debug Commands

```bash
# Check VM status
virsh list --all

# Check network
virsh net-list --all
virsh net-info default

# Check K3s status
kubectl get nodes -o wide
kubectl describe node <NODE_NAME>

# Check pods
kubectl get pods --all-namespaces -o wide
kubectl describe pod <POD_NAME> -n <NAMESPACE>

# Check services
kubectl get svc --all-namespaces
kubectl get endpoints --all-namespaces
```

## Verification Checklist

- [ ] VMs are running and accessible via SSH
- [ ] K3s server is running and healthy
- [ ] K3s worker nodes have joined the cluster
- [ ] Local registry is accessible and contains images
- [ ] Cluster shows all nodes as Ready
- [ ] Core DNS pods are running
- [ ] Metrics server is responding
- [ ] Offline image pulling works
- [ ] Network connectivity between nodes works

## Next Steps

After completing Day 1-2:

1. **Day 3-4**: Deploy core services (PostgreSQL, Keycloak, Gitea)
2. **Day 5-6**: Develop and package your Rust application
3. **Day 7-8**: Set up GitOps and service mesh
4. **Day 9-10**: Implement security and monitoring
5. **Day 11-12**: Final integration and testing

## Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Terraform Libvirt Provider](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Registry](https://docs.docker.com/registry/)
- [Cloud Native PostgreSQL](https://cloudnative-pg.io/)

