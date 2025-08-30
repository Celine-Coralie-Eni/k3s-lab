# Day 3-4: Core Services Deployment Guide

## Overview

This guide covers Days 3-4 of your K3s lab assignment, focusing on deploying the core services that will support your Rust application: PostgreSQL (CloudNativePG), Keycloak (authentication), and Gitea (Git repository management).

## Prerequisites

Before starting Day 3-4, ensure you have completed Day 1-2:

- ✅ K3s cluster running and healthy
- ✅ Local registry operational
- ✅ Essential images pre-pulled
- ✅ SSH access to cluster nodes

## What We're Deploying

### 1. **PostgreSQL (CloudNativePG)**
- **Purpose**: Database for your Rust application and other services
- **Operator**: CloudNativePG for Kubernetes-native PostgreSQL management
- **Features**: High availability, backup/restore, scaling

### 2. **Keycloak**
- **Purpose**: JWT authentication and authorization
- **Features**: OAuth 2.0, OpenID Connect, user management
- **Integration**: Will secure your Rust application

### 3. **Gitea**
- **Purpose**: Git repository management for GitOps
- **Features**: Web interface, SSH access, CI/CD integration
- **Integration**: Will host your application code and manifests

## Step-by-Step Deployment

### Step 1: Verify Day 1-2 Setup

First, ensure your infrastructure is ready:

```bash
# Run verification script
./scripts/verify-setup.sh
```

This will check:
- SSH keys are present
- VMs are running
- K3s cluster is healthy
- Local registry is accessible
- kubectl access is working

### Step 2: Deploy Core Services

Run the automated deployment:

```bash
# Deploy all core services
./scripts/deploy-day3-4.sh
```

This script will:
1. Verify prerequisites
2. Install Helm (if needed)
3. Add required Helm repositories
4. Deploy PostgreSQL with CloudNativePG
5. Deploy Keycloak with PostgreSQL backend
6. Deploy Gitea with PostgreSQL backend
7. Set up port forwarding for external access
8. Create cleanup scripts

### Step 3: Verify Deployment

Check that all services are running:

```bash
# Check service status
kubectl get pods --all-namespaces | grep -E "(postgres|keycloak|gitea)"

# Check services
kubectl get svc --all-namespaces | grep -E "(postgres|keycloak|gitea)"
```

Expected output:
```
NAMESPACE   NAME                    READY   STATUS    RESTARTS   AGE
postgres    postgres-cluster-1      1/1     Running   0          5m
keycloak    keycloak-xxx-xxx        1/1     Running   0          3m
gitea       gitea-xxx-xxx           1/1     Running   0          2m
```

## Service Configuration

### PostgreSQL Configuration

**Access Information:**
- **Host**: `postgres-cluster-rw.postgres.svc.cluster.local`
- **Port**: `5432`
- **Database**: `appdb`
- **Username**: `appuser`
- **Password**: `apppassword`

**Connection String for Rust App:**
```
postgresql://appuser:apppassword@postgres-cluster-rw.postgres.svc.cluster.local:5432/appdb
```

### Keycloak Configuration

**Access Information:**
- **URL**: `http://localhost:8080` (via port forwarding)
- **Admin Username**: `admin`
- **Admin Password**: `admin123`

**Initial Setup:**
1. Access Keycloak admin console
2. Create a new realm for your application
3. Create a client for JWT authentication
4. Configure user roles and permissions

### Gitea Configuration

**Access Information:**
- **URL**: `http://localhost:3000` (via port forwarding)
- **First Run**: Complete initial setup wizard

**Initial Setup:**
1. Access Gitea web interface
2. Complete first-run configuration
3. Create admin user
4. Create repository for your Rust application

## Manual Deployment (if automated script fails)

### Deploy PostgreSQL with CloudNativePG

```bash
# Add Helm repository
helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
helm repo update

# Install CloudNativePG operator
helm install cnpg cloudnative-pg/cloudnative-pg \
  --namespace postgres \
  --create-namespace

# Create PostgreSQL cluster
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster
  namespace: postgres
spec:
  instances: 1
  imageName: registry.local:5000/cloudnative-pg/postgresql:15.5
  bootstrap:
    initdb:
      database: appdb
      owner: appuser
      secret:
        name: postgres-secret
  storage:
    size: 10Gi
    storageClass: local-path
EOF
```

### Deploy Keycloak

```bash
# Create Keycloak deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - name: keycloak
        image: registry.local:5000/keycloak/keycloak:23.0.3
        args:
        - start-dev
        - --http-enabled=true
        - --http-port=8080
        env:
        - name: KEYCLOAK_ADMIN
          value: "admin"
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: "admin123"
        - name: KC_DB
          value: "postgres"
        - name: KC_DB_URL
          value: "jdbc:postgresql://postgres-cluster-rw.postgres.svc.cluster.local:5432/keycloak"
        - name: KC_DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: KC_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 8080
EOF
```

### Deploy Gitea

```bash
# Create Gitea deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gitea
  namespace: gitea
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gitea
  template:
    metadata:
      labels:
        app: gitea
    spec:
      containers:
      - name: gitea
        image: registry.local:5000/gitea/gitea:1.21.4
        args:
        - web
        env:
        - name: GITEA__database__DB_TYPE
          value: "postgres"
        - name: GITEA__database__HOST
          value: "postgres-cluster-rw.postgres.svc.cluster.local:5432"
        - name: GITEA__database__NAME
          value: "gitea"
        - name: GITEA__database__USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: GITEA__database__PASSWD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 3000
        - containerPort: 222
EOF
```

## Troubleshooting

### Common Issues

1. **PostgreSQL not starting:**
   ```bash
   # Check CloudNativePG operator
   kubectl get pods -n postgres
   kubectl logs -n postgres deployment/cnpg-cloudnative-pg
   
   # Check PostgreSQL cluster
   kubectl describe cluster postgres-cluster -n postgres
   ```

2. **Keycloak not accessible:**
   ```bash
   # Check Keycloak logs
   kubectl logs -n keycloak deployment/keycloak
   
   # Check database connection
   kubectl exec -n keycloak deployment/keycloak -- env | grep KC_DB
   ```

3. **Gitea setup issues:**
   ```bash
   # Check Gitea logs
   kubectl logs -n gitea deployment/gitea
   
   # Check database connection
   kubectl exec -n gitea deployment/gitea -- env | grep GITEA__database
   ```

### Debug Commands

```bash
# Check all pods
kubectl get pods --all-namespaces

# Check services
kubectl get svc --all-namespaces

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods --all-namespaces
kubectl top nodes
```

## Verification Checklist

- [ ] PostgreSQL cluster is Healthy
- [ ] Keycloak pod is Running
- [ ] Gitea pod is Running
- [ ] All services are accessible via port forwarding
- [ ] Keycloak admin console loads
- [ ] Gitea web interface loads
- [ ] Database connections work
- [ ] No error messages in logs

## Next Steps (Day 5-6)

After completing Day 3-4:

1. **Configure Keycloak:**
   - Create realm for your application
   - Set up OAuth 2.0 client
   - Configure JWT token settings

2. **Set up Gitea:**
   - Complete initial configuration
   - Create repository for your Rust app
   - Set up SSH access

3. **Begin Rust Development:**
   - Create Rust web application
   - Implement JWT authentication
   - Connect to PostgreSQL
   - Package with Docker

4. **Prepare for GitOps:**
   - Create Kubernetes manifests
   - Set up ArgoCD (Day 7-8)
   - Configure service mesh (Day 7-8)

## Security Considerations

- **Database Security**: PostgreSQL uses Kubernetes secrets for credentials
- **Authentication**: Keycloak provides enterprise-grade security
- **Network Security**: All services run within cluster network
- **Access Control**: Services use RBAC and network policies

## Performance Optimization

- **Resource Limits**: All services have defined resource requests/limits
- **Storage**: Using local-path storage class for simplicity
- **Scaling**: CloudNativePG supports horizontal scaling
- **Monitoring**: Ready for Prometheus/Grafana integration

## Backup and Recovery

- **PostgreSQL**: CloudNativePG provides automated backups
- **Configuration**: All manifests are version controlled
- **State**: Kubernetes state is managed by etcd
- **Registry**: Local registry data can be backed up

This completes the core services deployment for Day 3-4. Your infrastructure is now ready for application development in Day 5-6!
