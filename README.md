# K3s Lab - Offline Kubernetes Infrastructure

This project sets up a complete offline Kubernetes environment using K3s, with all the components required for the assignment.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Control VM    │    │   Worker VM     │    │   Local Host    │
│   (K3s Server)  │    │   (K3s Agent)   │    │   (Terraform)   │
│                 │    │                 │    │                 │
│ - K3s Server    │    │ - K3s Agent     │    │ - Terraform     │
│ - Keycloak      │    │ - PostgreSQL    │    │ - Ansible       │
│ - Gitea         │    │ - App Pods      │    │ - Local Registry│
│ - Linkerd       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

- Vagrant or Multipass VMs already created
- Ansible installed on local machine
- Terraform installed on local machine
- Docker installed on local machine

## Project Structure

```
k3s-lab/
├── terraform/           # Infrastructure provisioning
├── ansible/            # Configuration management
├── k8s/               # Kubernetes manifests
├── docker/            # Docker images and registry
├── scripts/           # Utility scripts
└── docs/              # Documentation and diagrams
```

## Setup Steps

### Day 1-2: Infrastructure Setup
1. **VM Configuration**: Configure VM networking and base packages
2. **K3s Installation**: Deploy lightweight Kubernetes cluster
3. **Offline Preparation**: Set up local DNS and image pre-pulling
4. **Local Registry**: Configure offline container registry

### Day 3-4: Core Services
1. **PostgreSQL**: Deploy CloudNativePG operator
2. **Keycloak**: Set up authentication service
3. **Gitea**: Deploy Git repository manager

### Day 5-6: Application Development
1. **Rust App**: Develop JWT-authenticated web application
2. **Docker**: Package application with Docker
3. **Deployment**: Create Kubernetes manifests

### Day 7-8: GitOps & Observability
1. **ArgoCD**: Deploy GitOps operator
2. **Linkerd**: Service mesh with mTLS
3. **Monitoring**: Set up observability stack

### Day 9-10: Security & Testing
1. **Security Hardening**: Implement security policies
2. **Testing**: Validate all components
3. **Documentation**: Create Mermaid diagrams

### Day 11-12: Final Integration
1. **End-to-End Testing**: Validate complete workflow
2. **Documentation**: Finalize all documentation
3. **Demo Preparation**: Prepare for presentation

## Quick Start

```bash
# 1. Configure VMs
cd terraform
terraform init
terraform plan
terraform apply

# 2. Configure K3s
cd ../ansible
ansible-playbook -i inventory k3s-setup.yml

# 3. Deploy core services
ansible-playbook -i inventory core-services.yml
```

## Offline Requirements

All components are designed to work offline:
- Pre-pulled container images
- Local container registry
- Offline package repositories
- Local DNS resolution

## Security Features

- JWT authentication with Keycloak
- mTLS encryption with Linkerd
- RBAC policies
- Network policies
- Secret management


