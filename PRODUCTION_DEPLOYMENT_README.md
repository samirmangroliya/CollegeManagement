# Production Deployment - Quick Start

This directory contains everything you need to deploy the College Management application to production.

## 📚 Documentation

1. **[PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)** - Complete deployment guide with multiple options
   - Docker Compose (self-hosted)
   - Azure Container Apps
   - Azure Kubernetes Service (AKS)
   - AWS ECS

2. **[DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)** - Pre-deployment checklist
   - Infrastructure setup
   - Security configuration
   - Testing procedures
   - Deployment day steps

3. **[OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md)** - Operations and troubleshooting guide
   - Common commands
   - Troubleshooting scenarios
   - Performance tuning
   - Monitoring and alerts

## 🚀 Quick Start (Azure AKS)

### Prerequisites
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
az aks install-cli

# Install Docker
docker --version  # Should be 20.10+
```

### Step 1: Set up Azure Resources
```bash
# Login to Azure
az login

# Create resource group
az group create --name college-management-rg --location eastus

# Create container registry
az acr create --resource-group college-management-rg \
  --name collegemanagementacr --sku Basic

# Create AKS cluster
az aks create \
  --resource-group college-management-rg \
  --name college-prod-aks \
  --node-count 2 \
  --enable-managed-identity

# Get credentials
az aks get-credentials \
  --resource-group college-management-rg \
  --name college-prod-aks
```

### Step 2: Prepare Configuration
```bash
# Clone the repository
git clone your-repo.git
cd CollegeManagement

# Create production configuration
cp .env.prod.example .env.prod

# Edit with your production values
nano .env.prod
```

### Step 3: Deploy Application
```bash
# Build and push image
docker build -t collegemanagementacr.azurecr.io/college-management:prod .
docker push collegemanagementacr.azurecr.io/college-management:prod

# Deploy to Kubernetes
chmod +x scripts/deploy.sh
./scripts/deploy.sh collegemanagementacr college-management prod k8s

# Verify deployment
kubectl get pods -n college-prod
kubectl get services -n college-prod
```

### Step 4: Verify Deployment
```bash
# Wait for service to get LoadBalancer IP
kubectl get service college-management-service -n college-prod -w

# Test health endpoint
curl http://<EXTERNAL-IP>/actuator/health
```

## 🐳 Quick Start (Docker Compose)

### Step 1: Prepare Configuration
```bash
# Create production environment file
cp .env.example .env

# Update with production credentials
nano .env
```

### Step 2: Deploy Services
```bash
# Start services
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps
```

### Step 3: Verify Deployment
```bash
# Check logs
docker-compose -f docker-compose.prod.yml logs -f spring-boot-app

# Test health endpoint
curl http://localhost:8080/actuator/health
```

## 📁 Project Structure

```
CollegeManagement/
├── PRODUCTION_DEPLOYMENT.md      # Deployment guide
├── DEPLOYMENT_CHECKLIST.md       # Pre-deployment checklist
├── OPERATIONS_GUIDE.md           # Operations guide
├── .env.prod.example             # Production env template
├── docker-compose.prod.yml       # Production compose
├── k8s/
│   └── deployment.yaml           # K8s manifests
├── scripts/
│   └── deploy.sh                 # Deployment script
├── .github/workflows/
│   └── deploy-prod.yml           # GitHub Actions CI/CD
└── [other application files]
```

## 🔐 Security Considerations

### Environment Variables
- Never commit `.env` or `.env.prod` files
- Use cloud secret management systems:
  - Azure Key Vault
  - AWS Secrets Manager
  - HashiCorp Vault
- Rotate credentials regularly

### Container Security
- Scan images for vulnerabilities: `docker scan college-management`
- Use non-root user (UID 1000)
- Enable security policies (PSP/SecurityPolicy)
- Keep base images updated

### Network Security
- Use private container registries
- Restrict database access to app only
- Enable TLS/SSL for all connections
- Use network policies to restrict traffic
- Configure firewalls appropriately

## 📊 Monitoring & Alerting

### Key Metrics to Monitor
- Pod restarts (should be minimal)
- CPU and memory usage
- Request latency
- Error rates
- Database connections

### Setting Up Monitoring
```bash
# View metrics
kubectl top pods -n college-prod
kubectl top nodes

# Port forward to local
kubectl port-forward svc/college-management-service 8080:80 -n college-prod

# Check health
curl http://localhost:8080/actuator/health
```

## 🔄 Deployment Workflow

### Development → Staging → Production

```
1. Developer pushes to `main` branch
   ↓
2. GitHub Actions runs tests and security scans
   ↓
3. Image is built and pushed to registry
   ↓
4. Manual approval required
   ↓
5. Automatic deployment to production
   ↓
6. Smoke tests verify deployment
   ↓
7. Notification sent to team
```

## 🆘 Troubleshooting

### Common Issues

**Application won't start**
```bash
kubectl logs <pod-name> -n college-prod
kubectl describe pod <pod-name> -n college-prod
```

**Can't connect to database**
```bash
# Test connectivity
telnet college-prod-db.postgres.database.azure.com 5432
```

**High memory usage**
```bash
kubectl top pod <pod-name> -n college-prod
```

See [OPERATIONS_GUIDE.md](./OPERATIONS_GUIDE.md) for more troubleshooting.

## 🚑 Rollback Procedures

### Kubernetes Rollback
```bash
# View deployment history
kubectl rollout history deployment/college-management-app -n college-prod

# Rollback to previous version
kubectl rollout undo deployment/college-management-app -n college-prod
```

### Docker Compose Rollback
```bash
# Stop current services
docker-compose -f docker-compose.prod.yml down

# Pull previous version
docker pull collegemanagementacr.azurecr.io/college-management:previous-tag

# Update docker-compose.yml with previous image tag
# Then restart
docker-compose -f docker-compose.prod.yml up -d
```

## 📞 Support & Documentation

- **Azure Documentation**: https://docs.microsoft.com/en-us/azure/aks/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Spring Boot Production**: https://spring.io/guides/topicals/spring-boot-docker/
- **PostgreSQL**: https://www.postgresql.org/docs/current/

## ✅ Production Readiness Checklist

Before deploying to production, ensure:

- [ ] All tests passing
- [ ] Security scan completed
- [ ] Database backups configured
- [ ] Monitoring and alerting set up
- [ ] Disaster recovery plan documented
- [ ] Load testing completed
- [ ] Security review completed
- [ ] Team trained on operations
- [ ] Runbooks documented
- [ ] Incident response procedures defined

---

**Last Updated**: 2026-08-15
**Maintainer**: DevOps Team
**Status**: Production Ready ✅
