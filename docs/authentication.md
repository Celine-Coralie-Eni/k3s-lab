# 🔐 Authentication & Authorization Documentation

## Authentication Flow Overview

```mermaid
sequenceDiagram
    participant User as User
    participant App as Application
    participant Keycloak as Keycloak
    participant API as Rust API
    
    User->>App: Access application
    App->>Keycloak: Redirect to login
    Keycloak->>User: Show login form
    User->>Keycloak: Enter credentials
    Keycloak->>App: Return JWT token
    App->>API: API call with JWT
    API->>Keycloak: Validate JWT
    Keycloak->>API: Return validation
    API->>App: Return data
```

## Detailed Authentication Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        USER[User] --> BROWSER[Web Browser]
        BROWSER --> APP[Frontend App]
    end
    
    subgraph "Authentication Layer"
        APP --> KEYCLOAK[Keycloak]
        KEYCLOAK --> REALM[Lab Realm]
        REALM --> CLIENT[Lab API Client]
    end
    
    subgraph "Authorization Layer"
        CLIENT --> JWT[JWT Token]
        JWT --> API[Rust API]
        API --> VALIDATE[Token Validation]
    end
    
    subgraph "Service Layer"
        VALIDATE --> SERVICE[Business Logic]
        SERVICE --> DB[PostgreSQL]
    end
```

## OIDC Flow Implementation

```mermaid
sequenceDiagram
    participant User as User
    participant Client as Client App
    participant Keycloak as Keycloak
    participant API as Rust API
    
    User->>Client: Access protected resource
    Client->>Keycloak: Authorization request
    Keycloak->>User: Login prompt
    User->>Keycloak: Provide credentials
    Keycloak->>Client: Authorization code
    Client->>Keycloak: Exchange code for token
    Keycloak->>Client: JWT access token
    Client->>API: API request with JWT
    API->>Keycloak: Validate JWT
    Keycloak->>API: Token validation response
    API->>Client: Protected resource data
```

## Keycloak Configuration

### Realm Setup

```mermaid
graph LR
    subgraph "Keycloak Realm"
        REALM[Lab Realm] --> CLIENTS[Clients]
        REALM --> USERS[Users]
        REALM --> ROLES[Roles]
    end
    
    subgraph "Client Configuration"
        CLIENTS --> LAB_API[lab-api Client]
        CLIENTS --> LAB_PUBLIC[lab-public Client]
    end
    
    subgraph "User Management"
        USERS --> TESTER[tester User]
        USERS --> ADMIN[admin User]
    end
    
    subgraph "Role Assignment"
        ROLES --> USER_ROLE[user Role]
        ROLES --> ADMIN_ROLE[admin Role]
    end
```

### Client Configuration

```yaml
# Keycloak Client Configuration
clientId: lab-api
clientType: confidential
standardFlowEnabled: true
directAccessGrantsEnabled: true
serviceAccountsEnabled: true
redirectUris:
  - "http://localhost:3000/*"
  - "http://rust-api.local/*"
webOrigins:
  - "http://localhost:3000"
  - "http://rust-api.local"
```

## JWT Token Structure

```mermaid
graph TB
    subgraph "JWT Header"
        HEADER[Header] --> ALG[Algorithm: RS256]
        HEADER --> TYP[Type: JWT]
    end
    
    subgraph "JWT Payload"
        PAYLOAD[Payload] --> ISS[Issuer: Keycloak]
        PAYLOAD --> SUB[Subject: User ID]
        PAYLOAD --> AUD[Audience: lab-api]
        PAYLOAD --> EXP[Expiration Time]
        PAYLOAD --> IAT[Issued At]
        PAYLOAD --> ROLES[Roles: user, admin]
    end
    
    subgraph "JWT Signature"
        SIGNATURE[Signature] --> VERIFY[RS256 Verification]
    end
```

## Rust API Integration

### JWT Validation Flow

```mermaid
sequenceDiagram
    participant Client as Client
    participant API as Rust API
    participant Keycloak as Keycloak
    participant JWKS as JWKS Endpoint
    
    Client->>API: Request with JWT
    API->>JWKS: Get public keys
    JWKS->>API: Return JWKS
    API->>API: Validate JWT signature
    API->>API: Check token claims
    API->>Client: Return response
```

### API Middleware Implementation

```rust
// JWT Validation Middleware
pub async fn jwt_middleware(
    req: ServiceRequest,
    next: Next<()>,
) -> Result<ServiceResponse, Error> {
    let token = extract_token_from_header(&req);
    
    match validate_jwt_token(&token).await {
        Ok(claims) => {
            req.extensions_mut().insert(claims);
            next.call(req).await
        }
        Err(_) => Err(ErrorUnauthorized("Invalid token"))
    }
}
```

## Service Mesh Integration

### mTLS with Authentication

```mermaid
graph TB
    subgraph "Service Communication"
        SVC1[Service A] --> PROXY1[Linkerd Proxy]
        SVC2[Service B] --> PROXY2[Linkerd Proxy]
    end
    
    subgraph "mTLS Handshake"
        PROXY1 --> MTLS[mTLS Encryption]
        PROXY2 --> MTLS
    end
    
    subgraph "Identity Verification"
        MTLS --> IDENTITY[Service Identity]
        IDENTITY --> CERT[Certificate Validation]
    end
```

### Linkerd Identity Integration

```yaml
# Service Account with Identity
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rust-api
  namespace: default
  annotations:
    linkerd.io/inject: enabled
```

## Security Policies

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: rust-api-policy
spec:
  podSelector:
    matchLabels:
      app: rust-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: keycloak
    ports:
    - protocol: TCP
      port: 8080
```

### RBAC Configuration

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: rust-api-role
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
```

## Token Refresh Flow

```mermaid
sequenceDiagram
    participant Client as Client
    participant API as Rust API
    participant Keycloak as Keycloak
    
    Client->>API: Request with expired JWT
    API->>API: Detect expired token
    API->>Client: Return 401 Unauthorized
    Client->>Keycloak: Request new token
    Keycloak->>Client: Return new JWT
    Client->>API: Retry with new token
    API->>Client: Return response
```

## Multi-Factor Authentication

### MFA Flow

```mermaid
sequenceDiagram
    participant User as User
    participant Keycloak as Keycloak
    participant MFA as MFA Provider
    
    User->>Keycloak: Login with password
    Keycloak->>MFA: Trigger MFA challenge
    MFA->>User: Send MFA code
    User->>Keycloak: Enter MFA code
    Keycloak->>MFA: Validate MFA code
    MFA->>Keycloak: MFA success
    Keycloak->>User: Return JWT token
```

## Security Best Practices

### 1. **Token Management**
- Use short-lived access tokens (15 minutes)
- Implement refresh token rotation
- Store tokens securely (httpOnly cookies)

### 2. **Keycloak Configuration**
- Enable HTTPS only
- Configure proper CORS policies
- Use strong password policies

### 3. **API Security**
- Validate all JWT claims
- Implement rate limiting
- Use HTTPS for all communications

### 4. **Service Mesh Security**
- Enable mTLS for all services
- Use network policies
- Implement service-to-service authentication

## Troubleshooting Authentication

### Common Issues

**Issue**: JWT validation failing
```bash
# Check Keycloak logs
kubectl logs -n keycloak deployment/keycloak

# Verify JWKS endpoint
curl http://keycloak.local/realms/lab/protocol/openid-connect/certs
```

**Issue**: mTLS not working
```bash
# Check Linkerd status
linkerd check

# Verify service identity
kubectl get pods -o wide
```

**Issue**: Token expiration
```bash
# Check token claims
echo $JWT_TOKEN | base64 -d | jq

# Refresh token
curl -X POST http://keycloak.local/realms/lab/protocol/openid-connect/token
```

## Monitoring & Observability

### Authentication Metrics

```mermaid
graph LR
    subgraph "Metrics Collection"
        KEYCLOAK[Keycloak] --> METRICS[Prometheus]
        API[Rust API] --> METRICS
        LINKERD[Linkerd] --> METRICS
    end
    
    subgraph "Dashboards"
        METRICS --> GRAFANA[Grafana]
        GRAFANA --> AUTH_DASH[Authentication Dashboard]
        GRAFANA --> SEC_DASH[Security Dashboard]
    end
```

### Key Metrics

| Metric | Description | Target |
|--------|-------------|---------|
| **Login Success Rate** | Percentage of successful logins | > 99% |
| **Token Validation Time** | JWT validation latency | < 100ms |
| **mTLS Handshake Time** | Service-to-service handshake | < 50ms |
| **Failed Authentication** | Number of failed auth attempts | < 1% |

---

*"Security is not a product, but a process."* 🔒
