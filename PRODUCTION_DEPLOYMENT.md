# Production Deployment Guide

## 🚀 Production Deployment Options

### Option 1: Docker Compose (Self-Hosted Server)

#### Setup Production Environment
```bash
# SSH into your production server
ssh user@production-server.com

# Clone your repository
git clone your-repo.git
cd CollegeManagement

# Copy the example file
cp .env.example .env

# Edit with PRODUCTION credentials
nano .env
```

**.env (Production)**
```
# PostgreSQL Configuration
POSTGRES_DB=college_prod_db
POSTGRES_USER=college_prod_user
POSTGRES_PASSWORD=SuperSecurePassword123!@#

# MongoDB Configuration
MONGO_INITDB_DATABASE=college_prod_logs

# Spring Boot Configuration
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/college_prod_db
SPRING_DATASOURCE_USERNAME=college_prod_user
SPRING_DATASOURCE_PASSWORD=SuperSecurePassword123!@#
SPRING_PROFILES_ACTIVE=prod
```

#### Run Production Services
```bash
# Start services in background
docker-compose up -d

# View logs
docker-compose logs -f spring-boot-app

# Enable auto-restart on server reboot
docker-compose up -d --remove-orphans
```

---

### Option 2: Azure Container Apps (Recommended for Production)

#### Prerequisites
- Azure account with active subscription
- Azure CLI installed
- Container Registry (Azure Container Registry)

#### Step 1: Push Image to Container Registry
```bash
# Login to Azure
az login

# Create resource group
az group create --name college-management-rg --location eastus

# Create container registry
az acr create --resource-group college-management-rg \
  --name collegemanagementacr --sku Basic

# Login to registry
az acr login --name collegemanagementacr

# Build and push image
az acr build --registry collegemanagementacr \
  --image college-management:prod .
```

#### Step 2: Create PostgreSQL Database
```bash
# Create PostgreSQL Server
az postgres server create \
  --resource-group college-management-rg \
  --name college-prod-db-server \
  --location eastus \
  --admin-user dbadmin \
  --admin-password SuperSecurePassword123!@# \
  --sku-name B_Gen5_1 \
  --version 14

# Create database
az postgres db create \
  --resource-group college-management-rg \
  --server-name college-prod-db-server \
  --name college_prod_db

# Allow Azure services access
az postgres server firewall-rule create \
  --resource-group college-management-rg \
  --server-name college-prod-db-server \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

#### Step 3: Create Container App Environment
```bash
# Create environment
az containerapp env create \
  --name college-env \
  --resource-group college-management-rg \
  --location eastus

# Create Container App
az containerapp create \
  --name college-management-app \
  --resource-group college-management-rg \
  --environment college-env \
  --image collegemanagementacr.azurecr.io/college-management:prod \
  --registry-server collegemanagementacr.azurecr.io \
  --registry-username collegemanagementacr \
  --registry-password <password> \
  --target-port 8080 \
  --ingress external \
  --env-vars \
    SPRING_DATASOURCE_URL="jdbc:postgresql://college-prod-db-server.postgres.database.azure.com:5432/college_prod_db" \
    SPRING_DATASOURCE_USERNAME="dbadmin@college-prod-db-server" \
    SPRING_DATASOURCE_PASSWORD="SuperSecurePassword123!@#" \
    SPRING_PROFILES_ACTIVE="prod"
```

---

### Option 3: Azure Kubernetes Service (AKS) - High Availability

#### Prerequisites
- Azure CLI
- kubectl installed
- Helm (optional, for package management)

#### Step 1: Create AKS Cluster
```bash
# Create AKS cluster
az aks create \
  --resource-group college-management-rg \
  --name college-prod-aks \
  --node-count 2 \
  --vm-set-type VirtualMachineScaleSets \
  --load-balancer-sku standard \
  --enable-managed-identity

# Get credentials
az aks get-credentials \
  --resource-group college-management-rg \
  --name college-prod-aks
```

#### Step 2: Create Kubernetes Secrets
```bash
# Create namespace
kubectl create namespace college-prod

# Create secrets for database credentials
kubectl create secret generic db-credentials \
  --from-literal=username=college_prod_user \
  --from-literal=password=SuperSecurePassword123!@# \
  -n college-prod
```

#### Step 3: Deploy with Kubernetes Manifests
**k8s/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: college-management-app
  namespace: college-prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: college-management
  template:
    metadata:
      labels:
        app: college-management
    spec:
      containers:
      - name: college-management
        image: collegemanagementacr.azurecr.io/college-management:prod
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:postgresql://college-prod-db-server.postgres.database.azure.com:5432/college_prod_db"
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: college-management-service
  namespace: college-prod
spec:
  type: LoadBalancer
  selector:
    app: college-management
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

Deploy:
```bash
kubectl apply -f k8s/deployment.yaml
kubectl get services -n college-prod
```

---

### Option 4: AWS Deployment (ECS + RDS)

#### Step 1: Create RDS PostgreSQL Database
```bash
aws rds create-db-instance \
  --db-instance-identifier college-prod-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username dbadmin \
  --master-user-password SuperSecurePassword123!@# \
  --allocated-storage 20 \
  --db-name college_prod_db
```

#### Step 2: Push Image to ECR
```bash
# Create ECR repository
aws ecr create-repository --repository-name college-management

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push image
docker tag college-management:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/college-management:prod
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/college-management:prod
```

#### Step 3: Deploy to ECS
```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name college-prod

# Create task definition, service, etc.
# (See AWS documentation for detailed setup)
```

---

## 🔑 Production Best Practices

### Security Checklist
- [ ] Use managed secrets (Azure Key Vault, AWS Secrets Manager)
- [ ] Enable SSL/TLS for all connections
- [ ] Use network security groups/security groups
- [ ] Enable database encryption at rest
- [ ] Use strong, random passwords (min 12 chars with special chars)
- [ ] Restrict database access to app only
- [ ] Enable audit logging
- [ ] Use private container registries
- [ ] Enable auto-scaling policies
- [ ] Set up monitoring and alerts

### Configuration Management
- Never hardcode secrets
- Use environment variables from secret management
- Use separate configs for dev/staging/prod
- Store config in IaC (Infrastructure as Code)

### Database Backup Strategy
```bash
# PostgreSQL Backup
pg_dump -h college-prod-db-server.postgres.database.azure.com \
  -U dbadmin college_prod_db > backup.sql

# Schedule automated backups in cloud console
```

### Monitoring & Logging
```bash
# View application logs
docker-compose logs -f spring-boot-app

# Or check cloud monitoring dashboards
az monitor metrics list --resource-group college-management-rg
```

---

## 📋 Quick Decision Guide

| Scenario | Recommendation | Complexity |
|----------|---|----------|
| Simple deployment, low traffic | Docker Compose on VM | ⭐ Low |
| Medium traffic, production-ready | Azure Container Apps | ⭐⭐ Medium |
| High availability, auto-scaling | AKS or ECS | ⭐⭐⭐ High |
| Minimal management overhead | Azure App Service | ⭐ Low |

---

## 🚀 Recommended Production Setup (Azure)

1. **Database**: Azure Database for PostgreSQL (managed)
2. **App Container**: Azure Container Apps
3. **Registry**: Azure Container Registry
4. **Secrets**: Azure Key Vault
5. **Monitoring**: Azure Monitor
6. **CDN**: Azure CDN (optional)

This gives you enterprise-grade infrastructure with minimal operations overhead.
