# Production Deployment Guide

This guide covers deploying the K3s Lab Rust API to production on your VM.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx (80/443)│────│  Rust API (8080)│────│ PostgreSQL (5432)│
│   (Reverse Proxy)│    │   (Application) │    │   (Database)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   pgAdmin (8081)│
                    │ (DB Management) │
                    └─────────────────┘
```

## 📋 Prerequisites

- VM with Docker and Docker Compose installed
- At least 2GB RAM and 10GB disk space
- Ports 80, 443, 8080, 8081, 5432 available
- Root or sudo access

## 🚀 Quick Deployment

### 1. Clone and Setup

```bash
# Clone the repository to your VM
git clone <your-repo-url>
cd k3s-lab/rust-api

# Make scripts executable
chmod +x deploy-prod.sh
chmod +x setup.sh
chmod +x test_api.sh
```

### 2. Configure Environment

```bash
# Copy and edit production environment
cp env.production .env.production
nano .env.production
```

**Important: Update these values in `.env.production`:**
- `POSTGRES_PASSWORD`: Use a strong password (12+ characters)
- `JWT_SECRET`: Use a long random string (32+ characters)
- `PGADMIN_EMAIL`: Your email for pgAdmin access
- `PGADMIN_PASSWORD`: Strong password for pgAdmin

### 3. Deploy

```bash
# Run the deployment script
./deploy-prod.sh
```

## 🔐 Database Credentials

After deployment, your database will be accessible with:

- **Host**: `localhost` (or your VM IP)
- **Port**: `5432`
- **Database**: `k3s_lab_api`
- **Username**: `postgres`
- **Password**: Value from `POSTGRES_PASSWORD` in `.env.production`

## 🌐 Service Endpoints

| Service | URL | Description |
|---------|-----|-------------|
| API | `http://your-vm-ip:8080` | Direct API access |
| API (Nginx) | `http://your-vm-ip` | API through reverse proxy |
| pgAdmin | `http://your-vm-ip:8081` | Database management |
| Health Check | `http://your-vm-ip/health` | API health status |

## 🔧 Management Commands

### View Logs
```bash
# All services
docker-compose -f docker-compose.prod.yml logs -f

# Specific service
docker-compose -f docker-compose.prod.yml logs -f rust-api
docker-compose -f docker-compose.prod.yml logs -f postgres
```

### Stop Services
```bash
docker-compose -f docker-compose.prod.yml down
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Update and Redeploy
```bash
# Pull latest code
git pull

# Redeploy
./deploy-prod.sh
```

### Backup Database
```bash
# Create backup
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U postgres k3s_lab_api > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore backup
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres k3s_lab_api < backup_file.sql
```

## 🔒 Security Configuration

### 1. Firewall Setup

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # API (if needed externally)
sudo ufw enable
```

### 2. SSL Certificate Setup

For production, replace the self-signed certificate:

```bash
# Copy your SSL certificates
cp your-cert.pem nginx/ssl/cert.pem
cp your-key.pem nginx/ssl/key.pem

# Update nginx.conf to uncomment SSL lines
nano nginx/nginx.conf

# Restart nginx
docker-compose -f docker-compose.prod.yml restart nginx
```

### 3. Environment Security

- Use strong, unique passwords
- Rotate JWT secrets regularly
- Monitor logs for suspicious activity
- Keep Docker images updated

## 📊 Monitoring

### Health Checks
```bash
# API health
curl http://your-vm-ip/health

# Database health
docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U postgres
```

### Resource Usage
```bash
# Container resource usage
docker stats

# Disk usage
df -h

# Memory usage
free -h
```

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :8080
   
   # Stop conflicting service
   sudo systemctl stop conflicting-service
   ```

2. **Database connection issues**
   ```bash
   # Check database logs
   docker-compose -f docker-compose.prod.yml logs postgres
   
   # Test database connection
   docker-compose -f docker-compose.prod.yml exec postgres psql -U postgres -d k3s_lab_api
   ```

3. **API not responding**
   ```bash
   # Check API logs
   docker-compose -f docker-compose.prod.yml logs rust-api
   
   # Check if container is running
   docker-compose -f docker-compose.prod.yml ps
   ```

### Log Locations
- Application logs: `./logs/` directory
- Container logs: `docker-compose -f docker-compose.prod.yml logs`
- System logs: `/var/log/`

## 🔄 Updates and Maintenance

### Regular Maintenance Tasks

1. **Weekly**
   - Check logs for errors
   - Monitor resource usage
   - Review security updates

2. **Monthly**
   - Update Docker images
   - Rotate JWT secrets
   - Backup database

3. **Quarterly**
   - Review and update dependencies
   - Security audit
   - Performance optimization

### Update Process

```bash
# 1. Backup current deployment
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U postgres k3s_lab_api > backup.sql

# 2. Pull latest code
git pull origin main

# 3. Redeploy
./deploy-prod.sh

# 4. Verify deployment
curl http://your-vm-ip/health
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review application logs
3. Check system resources
4. Verify network connectivity
5. Ensure all prerequisites are met


