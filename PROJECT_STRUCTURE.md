# K3s Lab Project Structure

## Overview

This document provides a comprehensive overview of the K3s lab project structure, explaining the purpose and contents of each directory and file.

## Directory Structure

```
k3s-lab/
├── README.md                    # Main project documentation
├── PROJECT_STRUCTURE.md         # This file - project structure overview
├── terraform/                   # Infrastructure as Code (Terraform)
├── ansible/                     # Configuration Management (Ansible)
├── k8s/                        # Kubernetes manifests (future)
├── docker/                      # Docker images and registry config (future)
├── scripts/                     # Automation and utility scripts
└── docs/                        # Documentation and diagrams
```

## Detailed Component Breakdown

### 1. Root Level Files

#### `README.md`
- **Purpose**: Main project documentation and overview
- **Contents**: 
  - Project description and objectives
  - Architecture overview
  - Setup steps for all 12 days
  - Quick start guide
  - Offline requirements
  - Security features

#### `PROJECT_STRUCTURE.md`
- **Purpose**: This file - explains the project structure
- **Contents**: Detailed breakdown of all directories and files

### 2. `terraform/` Directory

**Purpose**: Infrastructure provisioning using Terraform

#### Files:
- **`main.tf`**: Main Terraform configuration
  - VM creation with libvirt
  - Cloud-init configuration
  - Network setup
  - Output definitions

- **`variables.tf`**: Variable definitions
  - VM specifications (CPU, memory, disk)
  - Network configuration
  - K3s version settings
  - Feature toggles

- **`outputs.tf`**: Output values
  - VM IP addresses
  - Connection information
  - Cluster details
  - Next steps guidance

- **`versions.tf`**: Provider requirements
  - Terraform version constraints
  - Libvirt provider configuration

- **`terraform.tfvars.example`**: Example configuration
  - Sample values for all variables
  - Copy to `terraform.tfvars` and customize

- **`cloud-init.tpl`**: VM initialization template
  - User setup and SSH configuration
  - Package installation
  - Docker and containerd setup
  - K3s prerequisites

### 3. `ansible/` Directory

**Purpose**: Configuration management and automation

#### Files:
- **`inventory`**: Host definitions
  - K3s server and worker nodes
  - Registry and service hosts
  - SSH configuration

- **`ansible.cfg`**: Ansible configuration
  - SSH settings
  - Privilege escalation
  - Performance optimizations

- **`requirements.yml`**: Collection dependencies
  - Required Ansible collections
  - Version constraints

- **`k3s-setup.yml`**: Main K3s installation playbook
  - K3s server setup
  - Worker node joining
  - Cluster configuration
  - Registry integration

- **`registry-setup.yml`**: Local registry setup
  - Docker registry deployment
  - Configuration and security
  - Service management

- **`pre-pull-images.yml`**: Image preparation
  - Essential image downloading
  - Local registry population
  - Offline capability setup

#### `ssh/` Subdirectory:
- **`README.md`**: SSH key setup instructions
- **`id_rsa`**: Private SSH key (generated)
- **`id_rsa.pub`**: Public SSH key (generated)

### 4. `k8s/` Directory

**Purpose**: Kubernetes manifests and configurations (Future)

#### Planned Contents:
- **`namespaces/`**: Namespace definitions
- **`deployments/`**: Application deployments
- **`services/`**: Service definitions
- **`ingress/`**: Ingress configurations
- **`configmaps/`**: Configuration data
- **`secrets/`**: Secret management
- **`rbac/`**: Role-based access control
- **`network-policies/`**: Network security policies

### 5. `docker/` Directory

**Purpose**: Docker images and registry configuration (Future)

#### Planned Contents:
- **`Dockerfile`**: Application containerization
- **`docker-compose.yml`**: Local development setup
- **`registry/`**: Registry configuration
- **`images/`**: Pre-built image scripts

### 6. `scripts/` Directory

**Purpose**: Automation and utility scripts

#### Files:
- **`setup-ssh.sh`**: SSH key generation
  - Automatic SSH key creation
  - Permission setup
  - Security configuration

- **`deploy-infrastructure.sh`**: Main deployment script
  - Prerequisites checking
  - Automated deployment pipeline
  - Progress monitoring
  - Error handling

### 7. `docs/` Directory

**Purpose**: Comprehensive documentation and diagrams

#### Files:
- **`architecture.md`**: System architecture
  - Mermaid diagrams
  - Component relationships
  - Network topology
  - Security model

- **`day1-2-setup.md`**: Detailed setup guide
  - Step-by-step instructions
  - Prerequisites
  - Troubleshooting
  - Verification checklist

## File Relationships and Dependencies

### Infrastructure Flow
```
terraform/main.tf → VMs Created
    ↓
ansible/inventory → Hosts Defined
    ↓
ansible/k3s-setup.yml → K3s Installed
    ↓
ansible/registry-setup.yml → Registry Running
    ↓
ansible/pre-pull-images.yml → Images Available
    ↓
k8s/ → Applications Deployed
```

### Configuration Dependencies
```
terraform/outputs.tf → ansible/inventory (IP addresses)
terraform/cloud-init.tpl → ansible/ssh/id_rsa.pub (SSH keys)
ansible/k3s-setup.yml → terraform outputs (server IP)
scripts/deploy-infrastructure.sh → All components
```

## Usage Patterns

### 1. Initial Setup
```bash
# Generate SSH keys
./scripts/setup-ssh.sh

# Deploy everything
./scripts/deploy-infrastructure.sh
```

### 2. Manual Deployment
```bash
# Terraform
cd terraform
terraform init
terraform plan
terraform apply

# Ansible
cd ../ansible
ansible-playbook -i inventory k3s-setup.yml
ansible-playbook -i inventory registry-setup.yml
ansible-playbook -i inventory pre-pull-images.yml
```

### 3. Development Workflow
```bash
# Test changes
cd terraform && terraform plan
cd ../ansible && ansible-playbook -i inventory k3s-setup.yml --check

# Apply changes
cd ../terraform && terraform apply
cd ../ansible && ansible-playbook -i inventory k3s-setup.yml
```

## Security Considerations

### SSH Keys
- Private keys stored in `ansible/ssh/`
- Public keys distributed via cloud-init
- Keys generated automatically by scripts

### Network Security
- VMs isolated in libvirt network
- Internal communication only
- No external internet access required

### Access Control
- Ubuntu user with sudo access
- SSH key-based authentication only
- No password authentication

## Maintenance and Updates

### Regular Tasks
1. **Image Updates**: Modify `ansible/pre-pull-images.yml`
2. **K3s Updates**: Update `terraform/variables.tf`
3. **Configuration Changes**: Modify Ansible playbooks
4. **Infrastructure Changes**: Update Terraform files

### Backup Strategy
- VM snapshots via libvirt
- K3s backup via etcd snapshots
- Registry data backup
- Configuration backup

## Troubleshooting Guide

### Common Issues
1. **VM Creation Fails**: Check libvirt and QEMU installation
2. **SSH Connection Fails**: Verify SSH keys and VM status
3. **K3s Not Starting**: Check system resources and logs
4. **Registry Issues**: Verify Docker and network connectivity

### Debug Commands
```bash
# Check VM status
virsh list --all

# Check K3s status
kubectl get nodes

# Check registry
curl http://registry.local:5000/v2/_catalog

# Check Ansible connectivity
ansible all -m ping -i inventory
```

## Future Enhancements

### Planned Features
1. **Monitoring Stack**: Prometheus, Grafana, AlertManager
2. **Logging**: ELK stack or Loki
3. **Backup Solutions**: Velero integration
4. **CI/CD**: GitHub Actions or GitLab CI
5. **Security Scanning**: Trivy, Falco
6. **Cost Optimization**: Resource monitoring and scaling

### Scalability Considerations
- Multi-node worker pools
- Load balancer integration
- Storage class management
- Network policy automation

This structure provides a solid foundation for your K3s lab assignment while maintaining flexibility for future enhancements and modifications.

