# 🏗️ Architecture Documentation

## System Architecture Overview

```mermaid
graph TB
    subgraph "Infrastructure Layer"
        TF[Terraform] --> ANS[Ansible]
        ANS --> K3S[K3s Cluster]
    end
    
    subgraph "Platform Layer"
        K3S --> ARGO[ArgoCD]
        K3S --> LINKERD[Linkerd Service Mesh]
        K3S --> KEYCLOAK[Keycloak Auth]
        K3S --> GITEA[Gitea Git Server]
    end
    
    subgraph "Application Layer"
        ARGO --> APP1[Hello World App]
        ARGO --> APP2[Rust API]
        ARGO --> APP3[Guestbook App]
    end
    
    subgraph "Security & Observability"
        LINKERD --> MTLS[mTLS Encryption]
        LINKERD --> VIZ[Linkerd Viz]
        KEYCLOAK --> JWT[JWT Tokens]
    end
```

## Detailed Component Architecture

```mermaid
graph LR
    subgraph "VM Layer"
        VM1[k3s-1<br/>Master Node]
        VM2[k3s-2<br/>Worker Node]
        VM3[k3s-3<br/>Worker Node]
    end
    
    subgraph "Kubernetes Layer"
        VM1 --> K8S[Kubernetes API Server]
        VM2 --> K8S
        VM3 --> K8S
    end
    
    subgraph "Platform Services"
        K8S --> ARGO[ArgoCD<br/>GitOps Controller]
        K8S --> LINKERD[Linkerd<br/>Service Mesh]
        K8S --> KEYCLOAK[Keycloak<br/>Identity Provider]
        K8S --> GITEA[Gitea<br/>Git Server]
    end
    
    subgraph "Applications"
        ARGO --> APP1[Hello World<br/>Test App]
        ARGO --> APP2[Rust API<br/>Backend Service]
        ARGO --> APP3[Guestbook<br/>Sample App]
    end
```

## Network Architecture

```mermaid
graph TB
    subgraph "External Access"
        USER[User] --> INGRESS[Ingress Controller]
    end
    
    subgraph "Kubernetes Cluster"
        INGRESS --> SVC1[Hello World Service]
        INGRESS --> SVC2[Rust API Service]
        INGRESS --> SVC3[Keycloak Service]
        INGRESS --> SVC4[Gitea Service]
        INGRESS --> SVC5[ArgoCD Service]
    end
    
    subgraph "Service Mesh"
        SVC1 --> PROXY1[Linkerd Proxy]
        SVC2 --> PROXY2[Linkerd Proxy]
        SVC3 --> PROXY3[Linkerd Proxy]
        SVC4 --> PROXY4[Linkerd Proxy]
        SVC5 --> PROXY5[Linkerd Proxy]
    end
    
    subgraph "Pods"
        PROXY1 --> POD1[Hello World Pod]
        PROXY2 --> POD2[Rust API Pod]
        PROXY3 --> POD3[Keycloak Pod]
        PROXY4 --> POD4[Gitea Pod]
        PROXY5 --> POD5[ArgoCD Pod]
    end
```

## Data Flow Architecture

```mermaid
sequenceDiagram
    participant User as User
    participant Ingress as Ingress
    participant Proxy as Linkerd Proxy
    participant App as Application
    participant DB as Database
    
    User->>Ingress: HTTP Request
    Ingress->>Proxy: Route to Service
    Proxy->>Proxy: mTLS Handshake
    Proxy->>App: Forward Request
    App->>DB: Database Query
    DB->>App: Return Data
    App->>Proxy: Response
    Proxy->>Proxy: mTLS Encryption
    Proxy->>Ingress: Encrypted Response
    Ingress->>User: HTTP Response
```

## Security Architecture

```mermaid
graph TB
    subgraph "Authentication Layer"
        USER[User] --> KEYCLOAK[Keycloak]
        KEYCLOAK --> JWT[JWT Token]
    end
    
    subgraph "Authorization Layer"
        JWT --> API[Rust API]
        API --> VALIDATE[Token Validation]
    end
    
    subgraph "Network Security"
        PROXY[Linkerd Proxy] --> MTLS[mTLS Encryption]
        MTLS --> SERVICE[Service Communication]
    end
    
    subgraph "Infrastructure Security"
        TERRAFORM[Terraform] --> SECRETS[Secret Management]
        ANSIBLE[Ansible] --> CONFIG[Secure Configuration]
    end
```

## Observability Architecture

```mermaid
graph LR
    subgraph "Data Collection"
        PROXY[Linkerd Proxy] --> METRICS[Metrics]
        PROXY --> TRACES[Traces]
        PROXY --> LOGS[Logs]
    end
    
    subgraph "Processing"
        METRICS --> PROMETHEUS[Prometheus]
        TRACES --> JAEGER[Jaeger]
        LOGS --> LOKI[Loki]
    end
    
    subgraph "Visualization"
        PROMETHEUS --> GRAFANA[Grafana]
        JAEGER --> GRAFANA
        LOKI --> GRAFANA
    end
    
    subgraph "Dashboards"
        GRAFANA --> DASH1[Service Mesh Dashboard]
        GRAFANA --> DASH2[Application Dashboard]
        GRAFANA --> DASH3[Infrastructure Dashboard]
    end
```