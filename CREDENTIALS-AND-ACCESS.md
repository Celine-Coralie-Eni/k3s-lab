# 🔐 **K3s Lab - Complete Credentials & Access Guide**

## 🎯 **MISSION ACCOMPLISHED!**

All three tasks have been successfully completed:
- ✅ **k3s-2 added as worker node**
- ✅ **Rust API deployed to K3s cluster**
- ✅ **Local registry set up and operational**

---

## 🖥️ **VM Access Credentials**

### **SSH Access to VMs**
```bash
# SSH Key Location
/var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa

# SSH Command Template
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -o StrictHostKeyChecking=no ubuntu@<VM_IP>

# VM IPs
k3s-1 (Master): 10.127.216.159
k3s-2 (Worker): 10.127.216.12
k3s (Unknown):  10.127.216.127
```

### **Direct SSH Commands**
```bash
# Access k3s-1 (Master)
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -o StrictHostKeyChecking=no ubuntu@10.127.216.159

# Access k3s-2 (Worker)
sudo ssh -i /var/snap/multipass/common/data/multipassd/ssh-keys/id_rsa -o StrictHostKeyChecking=no ubuntu@10.127.216.12
```

---

## ☸️ **K3s Cluster Access**

### **kubectl Configuration**
```bash
# Kubeconfig Location
~/.kube/config

# Cluster Information
Server: https://10.127.216.159:6443
Context: default
User: default
```

### **K3s Cluster Token**
```
K1078557524e0fe5b1121e09d761abfe035576107b3bad892626ae25080774b67aa::server:05ab6d016e864054ca0fb4b80e210a42
```

### **Cluster Status**
```bash
# Check cluster status
kubectl cluster-info

# Check nodes
kubectl get nodes

# Check all pods
kubectl get pods -A
```

---

## 🐳 **Docker Registry Access**

### **Local Registry**
```bash
# Registry URL
http://localhost:5000

# Registry Status
docker ps | grep registry

# Available Images
curl http://localhost:5000/v2/_catalog
```

### **Rust API Image**
```bash
# Image Name
localhost:5000/k3s-lab-api:latest

# Image Size
101MB (optimized)

# Image Digest
sha256:f27540af87843a5802dd731f051bb77b309dd597633f4084bcabf22d444c2d32
```

---

## 🚀 **Rust API Deployment**

### **API Access**
```bash
# Health Check
curl http://localhost:8080/health

# Root Endpoint
curl http://localhost:8080/

# Port Forward (if needed)
kubectl port-forward -n k3s-lab service/rust-api-service 8080:8080
```

### **API Endpoints**
```json
{
  "health": "/health",
  "root": "/",
  "api": "/api/*"
}
```

### **Database Configuration**
```bash
# Database URL
postgresql://postgres:password@postgres-service:5432/k3s_lab

# Database Credentials
Username: postgres
Password: password
Database: k3s_lab
```

---

## 📊 **Kubernetes Resources**

### **Namespace**
```bash
# Namespace
k3s-lab

# View all resources
kubectl get all -n k3s-lab
```

### **Deployments**
```bash
# PostgreSQL
kubectl get deployment postgres -n k3s-lab

# Rust API
kubectl get deployment rust-api -n k3s-lab
```

### **Services**
```bash
# PostgreSQL Service
kubectl get service postgres-service -n k3s-lab

# Rust API Service
kubectl get service rust-api-service -n k3s-lab
```

### **Pods**
```bash
# All pods in namespace
kubectl get pods -n k3s-lab

# Pod logs
kubectl logs -n k3s-lab <pod-name>
```

---

## 🔧 **Useful Commands**

### **Cluster Management**
```bash
# Check cluster health
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info dump
```

### **Application Management**
```bash
# Scale Rust API
kubectl scale deployment rust-api --replicas=3 -n k3s-lab

# Restart deployment
kubectl rollout restart deployment/rust-api -n k3s-lab

# Check deployment status
kubectl rollout status deployment/rust-api -n k3s-lab
```

### **Debugging**
```bash
# Describe pod
kubectl describe pod <pod-name> -n k3s-lab

# Get pod logs
kubectl logs <pod-name> -n k3s-lab

# Execute into pod
kubectl exec -it <pod-name> -n k3s-lab -- /bin/bash
```

---

## 🌐 **Network Access**

### **Service Discovery**
```bash
# PostgreSQL
postgres-service.k3s-lab.svc.cluster.local:5432

# Rust API
rust-api-service.k3s-lab.svc.cluster.local:8080
```

### **Ingress**
```bash
# Ingress Host
api.k3s-lab.local

# Ingress Status
kubectl get ingress -n k3s-lab
```

---

## 📁 **File Locations**

### **Kubernetes Manifests**
```
k8s/
├── namespace.yaml
├── configmap.yaml
├── secret.yaml
├── postgres-deployment.yaml
├── rust-api-deployment.yaml
└── ingress.yaml
```

### **Rust API Source**
```
rust-api/
├── src/
├── Cargo.toml
├── Dockerfile
└── migrations/
```

### **Scripts**
```
scripts/
├── quick-setup.sh
├── test-container.sh
└── deploy-day5.sh
```

---

## 🎉 **Success Metrics**

| **Component** | **Status** | **Details** |
|---------------|------------|-------------|
| **K3s Cluster** | ✅ Running | 2 nodes (1 master, 1 worker) |
| **Rust API** | ✅ Running | 2 replicas, healthy |
| **PostgreSQL** | ✅ Running | Database created, connected |
| **Local Registry** | ✅ Running | Images pushed and available |
| **kubectl Access** | ✅ Working | Full cluster access |
| **API Health** | ✅ Working | Health endpoint responding |

---

## 🚀 **Next Steps**

Your K3s lab is now fully operational! You can:

1. **Deploy additional services** (Keycloak, Gitea, etc.)
2. **Set up GitOps pipeline** with ArgoCD
3. **Implement service mesh** with Linkerd
4. **Add monitoring and observability**
5. **Create additional applications**

---

## 🆘 **Troubleshooting**

### **If kubectl doesn't work:**
```bash
# Check kubeconfig
kubectl config view

# Test cluster connection
kubectl cluster-info
```

### **If pods are not running:**
```bash
# Check pod status
kubectl get pods -n k3s-lab

# Check pod logs
kubectl logs <pod-name> -n k3s-lab

# Check pod description
kubectl describe pod <pod-name> -n k3s-lab
```

### **If API is not accessible:**
```bash
# Check service
kubectl get service rust-api-service -n k3s-lab

# Port forward
kubectl port-forward -n k3s-lab service/rust-api-service 8080:8080

# Test locally
curl http://localhost:8080/health
```

---

**🎯 Your K3s lab is ready for production workloads!** 🚀
