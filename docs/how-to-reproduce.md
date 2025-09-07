# 🚀 How to Reproduce This Epic Lab

## Complete Step-by-Step Reproduction Guide

This guide will walk you through reproducing the entire K3s lab from scratch. Follow these steps exactly, and you'll have your own production-ready Kubernetes platform!

## Prerequisites

### Required Software

```bash
# Check what you need
multipass version    # Multipass for VMs
terraform version    # Terraform for IaC
ansible --version   # Ansible for automation
kubectl version     # Kubernetes CLI
```

### Installation Commands

```bash
# Install Multipass (Ubuntu/Debian)
sudo snap install multipass

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Ansible
sudo apt update && sudo apt install ansible

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/Celine-Coralie-Eni/k3s-lab.git
cd k3s-lab

# Verify you have all the files
ls -la
```

## Step 2: Infrastructure Setup (Terraform)

### Configure Variables

```bash
# Copy the example variables file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the variables (optional - defaults work fine)
nano terraform/terraform.tfvars
```

### Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the infrastructure
terraform apply

# Wait for VMs to be ready
multipass list
```

**Expected Output:**
```
k3s-1    Running   10.127.216.159    ubuntu    22.04 LTS    2GB     5GB     2
k3s-2    Running   10.127.216.12     ubuntu    22.04 LTS    2GB     5GB     2  
k3s-3    Running   10.127.216.13     ubuntu    22.04 LTS    2GB     5GB     2
```

## Step 3: Configuration Management (Ansible)

### Generate SSH Key (if needed)

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k3s_lab_key -N ""

# Add public key to authorized_keys
cat ~/.ssh/k3s_lab_key.pub >> ~/.ssh/authorized_keys
```

### Run Ansible Playbook

```bash
# Navigate to project root
cd ..

# Run the Ansible playbook
ansible-playbook -i ansible/inventory ansible/site.yml

# Wait for K3s installation to complete
```

**Expected Output:**
```
PLAY [Install K3s Cluster] ****************************************************

TASK [k3s-install : Install K3s on master] ***********************************
changed: [k3s-1]

TASK [k3s-install : Install K3s on workers] ***********************************
changed: [k3s-2]
changed: [k3s-3]

PLAY RECAP ********************************************************************
k3s-1                     : ok=3    changed=2    unreachable=0    failed=0
k3s-2                     : ok=3    changed=2    unreachable=0    failed=0
k3s-3                     : ok=3    changed=2    unreachable=0    failed=0
```

## Step 4: Verify K3s Cluster

### Configure kubectl

```bash
# Copy kubeconfig from master node
multipass exec k3s-1 -- sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml

# Update server IP in kubeconfig
sed -i 's/127.0.0.1/10.127.216.159/g' kubeconfig.yaml

# Set KUBECONFIG
export KUBECONFIG=$(pwd)/kubeconfig.yaml

# Verify cluster
kubectl get nodes
```

**Expected Output:**
```
NAME    STATUS   ROLES                  AGE   VERSION
k3s-1   Ready    control-plane,master   2m    v1.28.0+k3s1
k3s-2   Ready    <none>                2m    v1.28.0+k3s1
k3s-3   Ready    <none>                2m    v1.28.0+k3s1
```

## Step 5: Deploy Platform Services

### Deploy ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -f k8s/argocd/ -n argocd

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Deploy Linkerd Service Mesh

```bash
# Install Linkerd CLI
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
export PATH=$PATH:/home/$USER/.linkerd2/bin

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# Install Linkerd
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -

# Install Linkerd Viz
linkerd viz install | kubectl apply -f -

# Verify installation
linkerd check
```

### Deploy Keycloak

```bash
# Deploy Keycloak
kubectl apply -f k8s/keycloak/

# Wait for Keycloak to be ready
kubectl wait --for=condition=available --timeout=300s deployment/keycloak -n keycloak

# Configure Keycloak (run bootstrap job)
kubectl apply -f k8s/keycloak/bootstrap-realm.yaml
```

### Deploy Gitea

```bash
# Deploy Gitea
kubectl apply -f k8s/gitea/

# Wait for Gitea to be ready
kubectl wait --for=condition=available --timeout=300s deployment/gitea -n gitea

# Create admin user
kubectl apply -f k8s/gitea/admin-job.yaml
```

## Step 6: Deploy Test Applications

### Deploy Hello World App

```bash
# Deploy the test application
kubectl apply -f k8s/test-app/argocd-app.yaml

# Wait for application to be ready
kubectl wait --for=condition=available --timeout=300s deployment/hello-world -n test-app

# Check application status
kubectl get applications -n argocd
```

### Enable Service Mesh

```bash
# Annotate namespace for sidecar injection
kubectl annotate namespace test-app linkerd.io/inject=enabled

# Restart deployment to inject sidecars
kubectl rollout restart deployment/hello-world -n test-app

# Verify sidecar injection
kubectl get pods -n test-app
```

**Expected Output:**
```
NAME                           READY   STATUS    RESTARTS   AGE
hello-world-854c47bc48-k9zc6   2/2     Running   0          1m
hello-world-854c47bc48-kqvrn   2/2     Running   0          1m
```

## Step 7: Access Your Applications

### Set up Port Forwarding

```bash
# ArgoCD UI
kubectl -n argocd port-forward svc/argocd-server 8080:443 &

# Keycloak Admin UI
kubectl -n keycloak port-forward svc/keycloak 8081:80 &

# Gitea UI
kubectl -n gitea port-forward svc/gitea 8082:3000 &

# Hello World App
kubectl -n test-app port-forward svc/hello-world 8083:80 &

# Linkerd Dashboard
linkerd viz dashboard &
```

### Access URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **ArgoCD** | https://localhost:8080 | admin / (password from secret) |
| **Keycloak** | http://localhost:8081 | admin / admin123 |
| **Gitea** | http://localhost:8082 | admin / admin123 |
| **Hello World** | http://localhost:8083 | - |
| **Linkerd Viz** | http://localhost:8084 | - |

## Step 8: Test the GitOps Pipeline

### Create a Test Change

```bash
# Edit the hello-world application
kubectl edit deployment hello-world -n test-app

# Change the image or add an environment variable
# Save and exit

# Watch ArgoCD sync the changes
kubectl get applications -n argocd -w
```

### Verify Service Mesh

```bash
# Check service mesh stats
linkerd viz stat deployment -n test-app

# Check mTLS status
linkerd check --proxy

# View traffic in dashboard
linkerd viz dashboard
```

## Step 9: Troubleshooting

### Common Issues and Solutions

**Issue**: VMs not starting
```bash
# Check Multipass status
multipass list

# Restart Multipass service
sudo systemctl restart snap.multipass.multipassd
```

**Issue**: K3s installation failing
```bash
# Check Ansible logs
ansible-playbook -i ansible/inventory ansible/site.yml -vvv

# Check VM connectivity
multipass exec k3s-1 -- ping -c 3 8.8.8.8
```

**Issue**: kubectl not working
```bash
# Check kubeconfig
cat kubeconfig.yaml

# Test connectivity
kubectl get nodes --kubeconfig=kubeconfig.yaml
```

**Issue**: ArgoCD not syncing
```bash
# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server

# Check application status
kubectl describe application hello-world-app -n argocd
```

**Issue**: Linkerd sidecars not injected
```bash
# Check namespace annotation
kubectl get namespace test-app -o yaml

# Restart deployment
kubectl rollout restart deployment/hello-world -n test-app
```

## Step 10: Verification Script

### Run Complete Verification

```bash
#!/bin/bash
# verify-complete-setup.sh

echo "🔍 Verifying complete lab setup..."

# Check VMs
echo "📱 Checking VMs..."
multipass list

# Check K3s cluster
echo "☸️  Checking K3s cluster..."
kubectl get nodes

# Check platform services
echo "🏗️  Checking platform services..."
kubectl get pods -A

# Check applications
echo "🚀 Checking applications..."
kubectl get applications -n argocd

# Check service mesh
echo "🌐 Checking service mesh..."
linkerd check

# Check mTLS
echo "🔒 Checking mTLS..."
linkerd viz stat deployment -n test-app

echo "✅ All verifications completed!"
```

## Step 11: Cleanup (Optional)

### Destroy Everything

```bash
# Destroy infrastructure
cd terraform
terraform destroy

# Remove Multipass instances
multipass delete k3s-1 k3s-2 k3s-3
multipass purge

# Clean up local files
rm -f kubeconfig.yaml
```

## Success Criteria

✅ **Infrastructure**: 3 VMs running K3s cluster  
✅ **Platform**: ArgoCD, Linkerd, Keycloak, Gitea deployed  
✅ **Applications**: Hello World app running with sidecars  
✅ **GitOps**: ArgoCD syncing from repository  
✅ **Service Mesh**: mTLS working, observability available  
✅ **Authentication**: Keycloak providing JWT tokens  

## Next Steps

Once you have the basic lab running:

1. **Explore ArgoCD UI** - See your applications
2. **Check Linkerd Dashboard** - Monitor service mesh
3. **Test Keycloak** - Create users and clients
4. **Use Gitea** - Set up repositories
5. **Deploy More Apps** - Try the Rust API
6. **Experiment** - Make changes and see GitOps in action

## Support

If you run into issues:

1. **Check the logs**: `kubectl logs -f deployment/your-app`
2. **Verify connectivity**: `kubectl get pods -A`
3. **Check service mesh**: `linkerd check`
4. **Open an issue**: [GitHub Issues](https://github.com/Celine-Coralie-Eni/k3s-lab/issues)

---

## 🎉 Congratulations!

You've successfully reproduced the epic K3s lab! You now have:

- ✅ **Production-ready Kubernetes cluster**
- ✅ **GitOps pipeline with ArgoCD**
- ✅ **Service mesh with Linkerd**
- ✅ **Authentication with Keycloak**
- ✅ **Git server with Gitea**
- ✅ **Automated deployments**

**This is not just a lab - it's a masterpiece of modern DevOps!** 🚀

*"From zero to hero, one command at a time."* ✨
