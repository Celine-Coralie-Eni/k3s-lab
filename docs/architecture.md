# K3s Lab Architecture

## System Overview

This document describes the architecture of the K3s lab infrastructure, designed to run completely offline with all necessary services for the assignment.

## High-Level Architecture

```mermaid
graph TB
    subgraph "Local Host"
        TF[Terraform]
        ANS[Ansible]
        DOCKER[Docker]
        REG[Local Registry]
    end
    
    subgraph "K3s Cluster"
        subgraph "Control Plane"
            K3S_SERVER[K3s Server]
            KEYCLOAK[Keycloak]
            GITEA[Gitea]
            ARGOCD[ArgoCD]
        end
        
        subgraph "Worker Nodes"
            K3S_WORKER1[K3s Worker 1]
            K3S_WORKER2[K3s Worker 2]
            POSTGRES[PostgreSQL]
            APP[Your Rust App]
        end
    end
    
    subgraph "Service Mesh"
        LINKERD[Linkerd]
        PROXY[Proxy Sidecar]
    end
    
    TF --> ANS
    ANS --> K3S_SERVER
    ANS --> K3S_WORKER1
    DOCKER --> REG
    REG --> K3S_SERVER
    REG --> K3S_WORKER1
    
    K3S_SERVER --> KEYCLOAK
    K3S_SERVER --> GITEA
    K3S_SERVER --> ARGOCD
    K3S_WORKER1 --> POSTGRES
    K3S_WORKER1 --> APP
    
    LINKERD --> K3S_SERVER
    LINKERD --> K3S_WORKER1
    PROXY --> APP
```

## Network Architecture

```mermaid
graph LR
    subgraph "Host Network"
        HOST[Your Machine]
    end
    
    subgraph "Libvirt Network (192.168.122.0/24)"
        SERVER[K3s Server<br/>192.168.122.10]
        WORKER1[K3s Worker 1<br/>192.168.122.11]
        REGISTRY[Local Registry<br/>192.168.122.100]
        SERVICES[Offline Services<br/>192.168.122.101-103]
    end
    
    HOST --> SERVER
    HOST --> WORKER1
    HOST --> REGISTRY
    SERVER --> WORKER1
    SERVER --> REGISTRY
    WORKER1 --> REGISTRY
```

## Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant A as Your App
    participant K as Keycloak
    participant K8S as Kubernetes
    
    U->>A: Access Application
    A->>K: Redirect to Login
    U->>K: Login with Credentials
    K->>A: Return with JWT Token
    A->>K8S: API Request with JWT
    K8S->>K: Validate JWT Token
    K->>K8S: Token Valid
    K8S->>A: Return Requested Data
    A->>U: Display Data
```

## GitOps Pipeline

```mermaid
graph LR
    subgraph "Git Repository"
        MANIFESTS[K8s Manifests]
        HELM[Helm Charts]
        ARGO[ArgoCD Config]
    end
    
    subgraph "ArgoCD"
        APP[Application Controller]
        SYNC[Sync Engine]
    end
    
    subgraph "K3s Cluster"
        NS[Namespaces]
        DEP[Deployments]
        SVC[Services]
        ING[Ingress]
    end
    
    MANIFESTS --> APP
    HELM --> APP
    ARGO --> APP
    APP --> SYNC
    SYNC --> NS
    SYNC --> DEP
    SYNC --> SVC
    SYNC --> ING
```

## Service Mesh Architecture

```mermaid
graph TB
    subgraph "Linkerd Control Plane"
        CP[Control Plane]
        ID[Identity Service]
        PROXY_INJ[Proxy Injector]
    end
    
    subgraph "Data Plane"
        subgraph "Namespace: default"
            APP[Your App]
            APP_PROXY[App Proxy]
        end
        
        subgraph "Namespace: postgres"
            DB[PostgreSQL]
            DB_PROXY[DB Proxy]
        end
    end
    
    CP --> ID
    CP --> PROXY_INJ
    PROXY_INJ --> APP_PROXY
    PROXY_INJ --> DB_PROXY
    
    APP --> APP_PROXY
    DB --> DB_PROXY
    
    APP_PROXY --> DB_PROXY
```

## Component Dependencies

```mermaid
graph TD
    subgraph "Infrastructure Layer"
        VMS[VMs]
        NET[Network]
        STORAGE[Storage]
    end
    
    subgraph "Platform Layer"
        K3S[K3s]
        DOCKER[Docker]
        REGISTRY[Registry]
    end
    
    subgraph "Core Services"
        POSTGRES[PostgreSQL]
        KEYCLOAK[Keycloak]
        GITEA[Gitea]
    end
    
    subgraph "Application Layer"
        RUST_APP[Rust App]
        ARGOCD[ArgoCD]
        LINKERD[Linkerd]
    end
    
    VMS --> K3S
    NET --> K3S
    STORAGE --> REGISTRY
    
    K3S --> POSTGRES
    K3S --> KEYCLOAK
    K3S --> GITEA
    
    POSTGRES --> RUST_APP
    KEYCLOAK --> RUST_APP
    GITEA --> ARGOCD
    
    ARGOCD --> RUST_APP
    LINKERD --> RUST_APP
```

## Security Model

```mermaid
graph TB
    subgraph "Authentication"
        JWT[JWT Tokens]
        OAUTH[OAuth 2.0]
        RBAC[RBAC]
    end
    
    subgraph "Network Security"
        MTLS[mTLS]
        NP[Network Policies]
        INGRESS[Ingress Rules]
    end
    
    subgraph "Data Security"
        SECRETS[K8s Secrets]
        ENCRYPTION[Data Encryption]
        BACKUP[Backup Encryption]
    end
    
    JWT --> RBAC
    OAUTH --> JWT
    RBAC --> NP
    MTLS --> NP
    NP --> INGRESS
    SECRETS --> ENCRYPTION
    ENCRYPTION --> BACKUP
```

## Monitoring and Observability

```mermaid
graph LR
    subgraph "Data Collection"
        METRICS[Metrics]
        LOGS[Logs]
        TRACES[Traces]
    end
    
    subgraph "Storage"
        PROMETHEUS[Prometheus]
        LOKI[Loki]
        TEMPO[Tempo]
    end
    
    subgraph "Visualization"
        GRAFANA[Grafana]
        DASHBOARDS[Dashboards]
        ALERTS[Alerts]
    end
    
    METRICS --> PROMETHEUS
    LOGS --> LOKI
    TRACES --> TEMPO
    
    PROMETHEUS --> GRAFANA
    LOKI --> GRAFANA
    TEMPO --> GRAFANA
    
    GRAFANA --> DASHBOARDS
    GRAFANA --> ALERTS
```

