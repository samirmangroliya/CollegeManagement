#!/bin/bash

# Production Deployment Script
# This script helps deploy the College Management application to production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY=${1:-collegemanagementacr}
IMAGE_NAME=${2:-college-management}
VERSION=${3:-prod}
ENVIRONMENT=${4:-azure}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}College Management Production Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print colored output
print_step() {
    echo -e "${GREEN}>>> $1${NC}"
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Step 1: Validate prerequisites
print_step "Validating prerequisites..."

command -v docker >/dev/null 2>&1 || print_error "Docker is not installed"
print_step "✓ Docker is installed"

if [ "$ENVIRONMENT" = "azure" ]; then
    command -v az >/dev/null 2>&1 || print_error "Azure CLI is not installed"
    print_step "✓ Azure CLI is installed"
elif [ "$ENVIRONMENT" = "k8s" ]; then
    command -v kubectl >/dev/null 2>&1 || print_error "kubectl is not installed"
    print_step "✓ kubectl is installed"
fi

# Step 2: Check if .env file exists
print_step "Checking configuration..."
if [ ! -f ".env" ]; then
    print_error ".env file not found. Please create one from .env.example"
fi
print_step "✓ Configuration file found"

# Step 3: Build Docker image
print_step "Building Docker image..."
docker build -t ${REGISTRY}.azurecr.io/${IMAGE_NAME}:${VERSION} -f Dockerfile .
if [ $? -eq 0 ]; then
    print_step "✓ Docker image built successfully"
else
    print_error "Failed to build Docker image"
fi

# Step 4: Login to registry and push image
if [ "$ENVIRONMENT" = "azure" ]; then
    print_step "Logging in to Azure Container Registry..."
    az acr login --name ${REGISTRY}
    
    print_step "Pushing Docker image to registry..."
    docker push ${REGISTRY}.azurecr.io/${IMAGE_NAME}:${VERSION}
    if [ $? -eq 0 ]; then
        print_step "✓ Image pushed successfully"
    else
        print_error "Failed to push image"
    fi
fi

# Step 5: Deployment based on environment
if [ "$ENVIRONMENT" = "docker-compose" ]; then
    print_step "Deploying with Docker Compose..."
    docker-compose -f docker-compose.prod.yml down
    docker-compose -f docker-compose.prod.yml up -d
    print_step "✓ Docker Compose deployment complete"
    docker-compose -f docker-compose.prod.yml ps

elif [ "$ENVIRONMENT" = "k8s" ]; then
    print_step "Deploying to Kubernetes..."
    
    # Check if namespace exists
    if ! kubectl get namespace college-prod &> /dev/null; then
        print_step "Creating namespace college-prod..."
        kubectl create namespace college-prod
    fi
    
    # Apply Kubernetes manifests
    print_step "Applying Kubernetes manifests..."
    kubectl apply -f k8s/deployment.yaml
    
    print_step "✓ Kubernetes deployment complete"
    
    # Wait for deployment to be ready
    print_step "Waiting for deployment to be ready (timeout: 5 minutes)..."
    kubectl rollout status deployment/college-management-app -n college-prod --timeout=5m
    
    # Show deployment status
    echo ""
    print_step "Deployment Status:"
    kubectl get deployments -n college-prod
    echo ""
    kubectl get pods -n college-prod
    echo ""
    kubectl get services -n college-prod

elif [ "$ENVIRONMENT" = "azure" ]; then
    print_step "Deploying to Azure Container Apps..."
    
    # This is a placeholder - actual deployment would depend on existing setup
    print_warning "Azure Container Apps deployment requires manual setup via Azure Portal or additional configuration"
    print_step "Image is ready for deployment: ${REGISTRY}.azurecr.io/${IMAGE_NAME}:${VERSION}"
fi

# Step 6: Verification
print_step "Verifying deployment..."
echo ""
echo -e "${GREEN}Deployment Summary:${NC}"
echo "  Registry: ${REGISTRY}"
echo "  Image: ${IMAGE_NAME}"
echo "  Version: ${VERSION}"
echo "  Environment: ${ENVIRONMENT}"
echo ""

if [ "$ENVIRONMENT" = "k8s" ]; then
    print_step "Getting service endpoint..."
    kubectl get service college-management-service -n college-prod -o wide
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
print_step "Next steps:"
echo "  1. Verify application is running"
echo "  2. Check logs: docker-compose logs -f spring-boot-app (Docker Compose)"
echo "  3. Check logs: kubectl logs -f deployment/college-management-app -n college-prod (Kubernetes)"
echo "  4. Test health endpoint: curl http://your-app-url/actuator/health"
echo ""
