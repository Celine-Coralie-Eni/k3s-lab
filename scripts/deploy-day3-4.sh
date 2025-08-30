#!/bin/bash

# Deploy Day 3-4 Core Services
# This script deploys PostgreSQL, Keycloak, and Gitea

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Starting Day 3-4 Core Services Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verify Day 1-2 setup
verify_prerequisites() {
    print_status "Verifying Day 1-2 setup..."
    
    # Check if verification script exists and run it
    if [ -f "$SCRIPT_DIR/verify-setup.sh" ]; then
        bash "$SCRIPT_DIR/verify-setup.sh"
    else
        print_warning "Verification script not found, checking basic requirements..."
        
        # Basic checks
        if [ ! -f "$PROJECT_DIR/ansible/ssh/id_rsa" ]; then
            print_error "SSH keys not found. Run: ./scripts/setup-ssh.sh"
            exit 1
        fi
        
        if [ ! -f "$PROJECT_DIR/terraform/terraform.tfstate" ]; then
            print_error "Terraform state not found. Run: ./scripts/deploy-infrastructure.sh"
            exit 1
        fi
    fi
}

# Install Helm if not present
install_helm() {
    print_status "Checking Helm installation..."
    
    if ! command -v helm &> /dev/null; then
        print_status "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        print_success "Helm is already installed"
    fi
}

# Add required Helm repositories
setup_helm_repos() {
    print_status "Setting up Helm repositories..."
    
    # Add CloudNativePG repository
    helm repo add cloudnative-pg https://cloudnative-pg.github.io/charts
    helm repo update
    
    print_success "Helm repositories configured"
}

# Deploy core services
deploy_core_services() {
    print_status "Deploying core services..."
    
    cd "$PROJECT_DIR/ansible"
    
    # Run the core services deployment playbook
    ansible-playbook -i inventory deploy-core-services.yml
    
    print_success "Core services deployment completed!"
}

# Verify services
verify_services() {
    print_status "Verifying deployed services..."
    
    # Get server IP
    cd "$PROJECT_DIR/terraform"
    local server_ip=$(terraform output -raw k3s_server_ip 2>/dev/null || echo "")
    
    if [ -n "$server_ip" ]; then
        print_status "Checking service status on $server_ip..."
        
        # Check PostgreSQL
        ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" ubuntu@"$server_ip" "
            echo '=== PostgreSQL Status ==='
            kubectl get pods -n postgres
            echo ''
            echo '=== Keycloak Status ==='
            kubectl get pods -n keycloak
            echo ''
            echo '=== Gitea Status ==='
            kubectl get pods -n gitea
            echo ''
            echo '=== Services ==='
            kubectl get svc --all-namespaces | grep -E '(postgres|keycloak|gitea)'
        "
    fi
}

# Setup port forwarding for access
setup_port_forwarding() {
    print_status "Setting up port forwarding for external access..."
    
    cd "$PROJECT_DIR/terraform"
    local server_ip=$(terraform output -raw k3s_server_ip 2>/dev/null || echo "")
    
    if [ -n "$server_ip" ]; then
        print_status "Starting port forwarding..."
        
        # Start port forwarding in background
        ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" -L 8080:keycloak.keycloak.svc.cluster.local:8080 ubuntu@"$server_ip" -N &
        local keycloak_pid=$!
        
        ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" -L 3000:gitea.gitea.svc.cluster.local:3000 ubuntu@"$server_ip" -N &
        local gitea_pid=$!
        
        ssh -i "$PROJECT_DIR/ansible/ssh/id_rsa" -L 5432:postgres-cluster-rw.postgres.svc.cluster.local:5432 ubuntu@"$server_ip" -N &
        local postgres_pid=$!
        
        # Save PIDs for cleanup
        echo "$keycloak_pid" > /tmp/keycloak_portforward.pid
        echo "$gitea_pid" > /tmp/gitea_portforward.pid
        echo "$postgres_pid" > /tmp/postgres_portforward.pid
        
        print_success "Port forwarding started"
        print_status "Access services at:"
        print_status "- Keycloak: http://localhost:8080"
        print_status "- Gitea: http://localhost:3000"
        print_status "- PostgreSQL: localhost:5432"
    fi
}

# Create cleanup script
create_cleanup_script() {
    print_status "Creating cleanup script..."
    
    cat > "$SCRIPT_DIR/cleanup-portforward.sh" << 'EOF'
#!/bin/bash
# Cleanup port forwarding

echo "Cleaning up port forwarding..."

if [ -f /tmp/keycloak_portforward.pid ]; then
    kill $(cat /tmp/keycloak_portforward.pid) 2>/dev/null || true
    rm /tmp/keycloak_portforward.pid
fi

if [ -f /tmp/gitea_portforward.pid ]; then
    kill $(cat /tmp/gitea_portforward.pid) 2>/dev/null || true
    rm /tmp/gitea_portforward.pid
fi

if [ -f /tmp/postgres_portforward.pid ]; then
    kill $(cat /tmp/postgres_portforward.pid) 2>/dev/null || true
    rm /tmp/postgres_portforward.pid
fi

echo "Port forwarding cleanup completed"
EOF

    chmod +x "$SCRIPT_DIR/cleanup-portforward.sh"
    print_success "Cleanup script created: $SCRIPT_DIR/cleanup-portforward.sh"
}

# Main deployment function
main() {
    echo "🎯 Day 3-4: Core Services Deployment"
    echo "====================================="
    
    # Verify prerequisites
    verify_prerequisites
    
    # Install and setup Helm
    install_helm
    setup_helm_repos
    
    # Deploy core services
    deploy_core_services
    
    # Verify deployment
    verify_services
    
    # Setup port forwarding
    setup_port_forwarding
    
    # Create cleanup script
    create_cleanup_script
    
    echo ""
    print_success "🎉 Day 3-4 deployment completed successfully!"
    echo ""
    echo "📋 Service Access Information:"
    echo "==============================="
    echo "🔐 Keycloak:"
    echo "   URL: http://localhost:8080"
    echo "   Username: admin"
    echo "   Password: admin123"
    echo ""
    echo "📚 Gitea:"
    echo "   URL: http://localhost:3000"
    echo "   First run setup required"
    echo ""
    echo "🗄️  PostgreSQL:"
    echo "   Host: localhost"
    echo "   Port: 5432"
    echo "   Database: appdb"
    echo "   Username: appuser"
    echo "   Password: apppassword"
    echo ""
    echo "🔗 Next Steps:"
    echo "1. Configure Keycloak realm and client for JWT auth"
    echo "2. Set up Gitea repository for your Rust app"
    echo "3. Begin Rust application development (Day 5-6)"
    echo "4. Deploy ArgoCD for GitOps (Day 7-8)"
    echo ""
    echo "🧹 To stop port forwarding: ./scripts/cleanup-portforward.sh"
    echo ""
    echo "💡 Ready to proceed with Day 5-6: Application Development!"
}

# Run main function
main "$@"
