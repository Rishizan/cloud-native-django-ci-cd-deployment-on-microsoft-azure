Production-Ready Django Deployment on Azure: Complete ACI & ACR DevOps Pipeline

![Azure](https://imgur.com/wLMcRHS.jpg)

**This comprehensive guide demonstrates how to deploy a Django-based production application onto Microsoft Azure using ACI (Azure Container Instances) and ACR (Azure Container Registry). We'll cover the complete DevOps pipeline from containerization to deployment, including security best practices, monitoring setup, and production optimization.**

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Django Web Framework](#django-web-framework)
- [Docker & Containerization](#docker--containerization)
- [Azure ACR Setup](#azure-acr-setup)
- [Azure ACI Deployment](#azure-aci-deployment)
- [Terraform Infrastructure as Code](#terraform-infrastructure-as-code)
- [CI/CD with GitHub Actions](#cicd-with-github-actions)
- [Security & Best Practices](#security--best-practices)
- [Monitoring & Logging](#monitoring--logging)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [Alternative Deployments](#alternative-deployments)

## 🎯 Overview

This project provides a complete DevOps pipeline for deploying Django applications on Microsoft Azure cloud infrastructure. The solution includes:

- **Containerization**: Docker-based application packaging
- **Registry Management**: Azure Container Registry (ACR) for secure image storage
- **Orchestration**: Azure Container Instances (ACI) for container management
- **Infrastructure as Code**: Terraform for automated resource provisioning
- **CI/CD Pipeline**: GitHub Actions for automated build and deployment
- **Security**: Azure RBAC, managed identities, and secrets management
- **Monitoring**: Azure Monitor integration and health checks

## 📚 Prerequisites

### Technical Requirements
- **Python 3.9+** installed locally
- **Docker Desktop** or Docker Engine
- **Azure Account** with an active subscription
- **Azure CLI** installed and configured
- **Terraform** (optional, for infrastructure deployment)
- **Django** framework knowledge
- **Basic understanding** of containers and cloud concepts

### Azure Permissions Required
- Azure Container Registry: Contributor access
- Azure Container Instances: Contributor access
- Resource Group: Contributor access
- Azure Monitor: Read/Write permissions (optional)

### Development Environment Setup
```bash
# Install Django and create project
pip install django
django-admin startproject myproject
cd myproject

# Create requirements file
pip freeze > requirements.txt

# Test locally
python manage.py runserver
```

## 🏗️ Project Structure

```
myproject/
├── myproject/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── __init__.py
│   └── [your-apps]
├── static/
├── media/
├── templates/
├── requirements.txt
├── Dockerfile
├── .dockerignore
├── .env.example
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/
│   └── workflows/
│       └── deploy.yml
└── README.md
```

## 🐍 Django Web Framework

**Django is a high-level Python web framework that encourages rapid development and clean, pragmatic design. Built by experienced developers, it takes care of much of the hassle of web development, so you can focus on writing your app without needing to reinvent the wheel.**

### Key Features
- **Batteries-included**: ORM, authentication, admin panel, forms
- **Security**: Built-in protection against CSRF, XSS, SQL injection
- **Scalability**: Designed for high-traffic applications
- **Documentation**: Comprehensive docs and active community
- **MVT Architecture**: Model-View-Template pattern

### Production Considerations
- **Static files handling**: Use Azure Blob Storage + Azure CDN
- **Database**: Azure Database for PostgreSQL/MySQL
- **Caching**: Azure Cache for Redis
- **Session storage**: Redis or database
- **Environment variables**: Azure Key Vault

## 🐳 Docker & Containerization

![Docker](https://imgur.com/raGErLx.png)

### What is Docker?

**Docker is an open platform for developing, shipping, and running applications in containers. Containerization provides a lightweight, portable way to package applications with all their dependencies, ensuring consistency across different environments.**

### Benefits of Containerization
- **Portability**: Run anywhere Docker is installed
- **Isolation**: Applications don't interfere with each other
- **Scalability**: Easy to scale horizontally
- **Version Control**: Image versioning and rollbacks
- **Resource Efficiency**: Shared OS kernel, lightweight

### Docker Workflow

1. **Write Dockerfile**: Define application environment
2. **Build Image**: Create container image with dependencies
3. **Test Locally**: Verify container works as expected
4. **Push to Registry**: Store in ACR for deployment
5. **Deploy**: Run containers in ACI

### Dockerfile Best Practices
- Use multi-stage builds for smaller images
- Leverage layer caching effectively
- Use specific base image versions
- Minimize attack surface
- Optimize for production performance

## 📦 Azure Container Registry (ACR)

**Azure Container Registry (ACR) is a managed, private Docker registry service based on the open-source Docker Registry 2.0. Use ACR to store and manage your private Docker container images and related artifacts.**

### Key Features
- **Fully Managed**: No infrastructure to maintain
- **Secure**: Azure AD integration and encryption
- **Geo-replication**: Replicate images across regions (Premium tier)
- **Integrated**: Works seamlessly with ACI, AKS, and other Azure services
- **Cost-effective**: Multiple pricing tiers to fit your needs
- **Vulnerability Scanning**: Automated security scans (Standard/Premium tiers)

### ACR Repository Setup

#### Step 1: Create Resource Group
```bash
# Create resource group
az group create \
    --name django-app-rg \
    --location eastus
```

#### Step 2: Create Container Registry
```bash
# Create ACR (Basic tier for development)
az acr create \
    --resource-group django-app-rg \
    --name mydjangoacr \
    --sku Basic \
    --admin-enabled true
```

#### Step 3: Get ACR Credentials
```bash
# Get ACR login server
az acr show --name mydjangoacr --query loginServer --output table

# Get admin credentials (for development)
az acr credential show --name mydjangoacr
```

### ACR Image Management

#### Build Docker Image
```bash
# Build the Docker image
docker build -t django-app:latest .

# Verify image creation
docker images | grep django-app
```

#### Authenticate with ACR
```bash
# Login to ACR
az acr login --name mydjangoacr

# Alternative: Docker login
docker login mydjangoacr.azurecr.io
```

#### Tag and Push Image
```bash
# Tag image for ACR
docker tag django-app:latest \
    mydjangoacr.azurecr.io/django-app:latest

# Push to ACR
docker push mydjangoacr.azurecr.io/django-app:latest
```

#### Build and Push Directly to ACR
```bash
# Build in ACR (recommended for production)
az acr build \
    --registry mydjangoacr \
    --image django-app:latest \
    --file Dockerfile .
```

#### Manage Images
```bash
# List repositories
az acr repository list --name mydjangoacr --output table

# List tags for a repository
az acr repository show-tags --name mydjangoacr --repository django-app --output table

# Delete an image tag
az acr repository delete --name mydjangoacr --image django-app:old-tag
```

## 🚀 Azure Container Instances (ACI)

**Azure Container Instances (ACI) offers the fastest and simplest way to run a container in Azure, without having to manage any virtual machines and without having to adopt a higher-level service. ACI is a great solution for scenarios that can operate in isolated containers, including simple applications, task automation, and build jobs.**

### Key ACI Features

- **Fast Startup**: Containers start in seconds
- **Per-Second Billing**: Pay only for what you use
- **Hypervisor Isolation**: Each container group runs in isolation
- **Custom Sizes**: Specify exact CPU and memory requirements
- **Persistent Storage**: Mount Azure Files shares
- **Linux and Windows**: Support for both container types

### ACI Deployment Options

#### Option 1: Azure CLI Deployment

```bash
# Create container instance
az container create \
    --resource-group django-app-rg \
    --name django-aci \
    --image mydjangoacr.azurecr.io/django-app:latest \
    --cpu 1 \
    --memory 1.5 \
    --registry-login-server mydjangoacr.azurecr.io \
    --registry-username <acr-username> \
    --registry-password <acr-password> \
    --dns-name-label django-app-unique \
    --ports 8000 \
    --environment-variables DJANGO_SETTINGS_MODULE=hello_world_django_app.settings
```

#### Option 2: Using Azure Portal

1. Navigate to Azure Portal
2. Search for "Container Instances"
3. Click "Create"
4. Fill in the required details:
   - Resource group: `django-app-rg`
   - Container name: `django-aci`
   - Image source: Azure Container Registry
   - Registry: Select your ACR
   - Image: `django-app:latest`
5. Configure networking (DNS name label)
6. Review and create

#### Check Container Status
```bash
# Get container details
az container show \
    --resource-group django-app-rg \
    --name django-aci \
    --output table

# Get container logs
az container logs \
    --resource-group django-app-rg \
    --name django-aci

# Get container events
az container attach \
    --resource-group django-app-rg \
    --name django-aci
```

#### Access Your Application
```bash
# Get the FQDN
az container show \
    --resource-group django-app-rg \
    --name django-aci \
    --query ipAddress.fqdn \
    --output tsv

# Access in browser: http://<fqdn>:8000
```

## 🏗️ Terraform Infrastructure as Code

This project includes Terraform configuration for automated infrastructure provisioning.

### Terraform Files Overview

- **main.tf**: Main infrastructure configuration
- **variables.tf**: Input variables for customization
- **outputs.tf**: Output values after deployment

### Deploy with Terraform

#### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```

#### Step 2: Review the Plan
```bash
terraform plan
```

#### Step 3: Apply Configuration
```bash
terraform apply
```

#### Step 4: Get Outputs
```bash
# Get ACR login server
terraform output acr_login_server

# Get ACI public IP
terraform output aci_public_ip

# Get ACI FQDN
terraform output aci_fqdn
```

#### Step 5: Build and Push Image to ACR
```bash
# Get ACR name from Terraform output
ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push from project root
cd ..
docker build -t $ACR_NAME.azurecr.io/devopsproj04:latest .
docker push $ACR_NAME.azurecr.io/devopsproj04:latest

# Or use ACR build
az acr build --registry $ACR_NAME --image devopsproj04:latest .
```

#### Step 6: Update Container Instance
```bash
# Restart the container to pull the latest image
az container restart \
    --resource-group devopsproj04-rg \
    --name devopsproj04-aci
```

### Customize Terraform Variables

Edit `terraform/variables.tf` or create a `terraform.tfvars` file:

```hcl
location     = "East US"
project_name = "mydjango"
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy
```

## 🔄 CI/CD with GitHub Actions

This project includes a GitHub Actions workflow for automated deployment.

### Workflow Overview

The `.github/workflows/deploy.yml` file automates:
1. Building the Docker image
2. Pushing to Azure Container Registry
3. Deploying to Azure Container Instances

### Setup GitHub Secrets

#### Step 1: Create Azure Service Principal
```bash
az ad sp create-for-rbac \
    --name "github-actions-sp" \
    --role contributor \
    --scopes /subscriptions/<subscription-id>/resourceGroups/devopsproj04-rg \
    --sdk-auth
```

Copy the JSON output.

#### Step 2: Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the JSON from Step 1
6. Click "Add secret"

### Trigger Deployment

Push to the `master` branch to trigger automatic deployment:

```bash
git add .
git commit -m "Deploy to Azure"
git push origin master
```

### Monitor Workflow

1. Go to the "Actions" tab in your GitHub repository
2. Click on the latest workflow run
3. Monitor the build and deployment progress

## 🔒 Security & Best Practices

### Container Security
- **Use non-root users** in containers (implemented in Dockerfile)
- **Scan images** for vulnerabilities using ACR scanning
- **Implement resource limits** to prevent resource exhaustion
- **Use Azure Key Vault** for secrets management
- **Keep base images updated** regularly

### Azure Security
- **Managed Identities**: Use instead of service principals when possible
- **Azure RBAC**: Principle of least privilege
- **Network Security Groups**: Control network access
- **Virtual Networks**: Isolate resources (for ACI with VNet integration)
- **Encryption**: Data at rest and in transit

### Django Security Settings
```python
# production.py
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True

# Use Azure Key Vault for secrets
SECRET_KEY = os.environ.get('SECRET_KEY')
```

### ACR Security Best Practices
```bash
# Enable admin user only for development
# For production, use managed identities or service principals

# Disable admin user
az acr update --name mydjangoacr --admin-enabled false

# Use repository-scoped tokens
az acr token create \
    --name django-token \
    --registry mydjangoacr \
    --scope-map _repositories_pull
```

## 📊 Monitoring & Logging

### Azure Monitor Integration

#### Enable Container Insights
```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
    --resource-group django-app-rg \
    --workspace-name django-logs

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group django-app-rg \
    --workspace-name django-logs \
    --query customerId -o tsv)

# Get workspace key
WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group django-app-rg \
    --workspace-name django-logs \
    --query primarySharedKey -o tsv)
```

#### Create Container with Logging
```bash
az container create \
    --resource-group django-app-rg \
    --name django-aci \
    --image mydjangoacr.azurecr.io/django-app:latest \
    --log-analytics-workspace $WORKSPACE_ID \
    --log-analytics-workspace-key $WORKSPACE_KEY
```

### View Logs
```bash
# View container logs
az container logs \
    --resource-group django-app-rg \
    --name django-aci \
    --follow

# View logs in Azure Portal
# Navigate to Container Instance → Logs
```

### Metrics to Monitor
- **CPU and Memory utilization**
- **Request/response times**
- **Container restart counts**
- **Network traffic**
- **Application-specific metrics**

### Health Checks

Add a health endpoint to your Django application:

```python
# views.py
from django.http import JsonResponse

def health_check(request):
    return JsonResponse({'status': 'healthy'}, status=200)

# urls.py
urlpatterns = [
    path('health/', health_check),
]
```

## 🛠️ Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check container state
az container show \
    --resource-group django-app-rg \
    --name django-aci \
    --query instanceView.state

# View detailed logs
az container logs \
    --resource-group django-app-rg \
    --name django-aci

# Check events
az container show \
    --resource-group django-app-rg \
    --name django-aci \
    --query instanceView.events
```

#### Image Pull Errors
```bash
# Verify ACR credentials
az acr credential show --name mydjangoacr

# Test ACR login
az acr login --name mydjangoacr

# Check image exists
az acr repository show --name mydjangoacr --repository django-app
```

#### Network Issues
```bash
# Check container IP and ports
az container show \
    --resource-group django-app-rg \
    --name django-aci \
    --query ipAddress

# Test connectivity
curl http://<fqdn>:8000/health/
```

#### Performance Issues
- **Monitor Azure Monitor metrics** for resource usage
- **Check container resource limits** (CPU, memory)
- **Review application logs** for errors
- **Consider scaling** to Azure Kubernetes Service (AKS) for production

## 💰 Cost Optimization

### ACI Cost Saving Tips
- **Use per-second billing** advantage - only pay when running
- **Right-size containers** based on actual usage
- **Stop containers** when not needed (development/testing)
- **Use Azure Reservations** for predictable workloads (up to 72% savings)
- **Monitor costs** with Azure Cost Management

### ACR Cost Management
- **Choose appropriate SKU**: Basic for development, Standard/Premium for production
- **Implement retention policies** to clean up old images
- **Use geo-replication** only when needed (Premium tier)
- **Optimize image sizes** with multi-stage builds

### Estimated Monthly Costs (East US)
- **ACR Basic**: ~$5/month (10 GB storage included)
- **ACI**: ~$0.0000012/vCPU-second + ~$0.00000013/GB-second
  - Example: 0.5 vCPU, 1.5 GB, 24/7 = ~$20-25/month

## 🔄 Alternative Deployments

### Azure App Service
- **Simplified deployment** with built-in CI/CD
- **Built-in load balancing** and auto-scaling
- **Managed platform** with automatic updates
- **Better for web applications** with persistent connections

### Azure Kubernetes Service (AKS)
- **Production-grade orchestration** for complex applications
- **Advanced scaling** and self-healing capabilities
- **Microservices architecture** support
- **Multi-container applications**

### Azure Web App for Containers
- **PaaS solution** for containerized web apps
- **Easy deployment** from ACR
- **Built-in CI/CD** integration
- **Custom domains and SSL** included

### Comparison

| Feature | ACI | App Service | AKS |
|---------|-----|-------------|-----|
| Complexity | Low | Low | High |
| Cost | Pay-per-use | Fixed pricing | Variable |
| Scaling | Manual | Auto | Advanced |
| Best For | Simple apps, jobs | Web apps | Microservices |

## 🎉 Success! 🎉

**Congratulations! You have successfully deployed your Django Application on Microsoft Azure using ACI and ACR with production-ready configurations.**

### Verification Steps
1. **Access your application** via the ACI FQDN
2. **Check container status** in Azure Portal
3. **Test application functionality**
4. **Monitor Azure Monitor metrics**
5. **Review security configurations**

### Post-Deployment Checklist
- [ ] SSL/TLS certificates configured (use Azure Application Gateway or Azure Front Door)
- [ ] Database configured (Azure Database for PostgreSQL/MySQL)
- [ ] Monitoring alerts set up in Azure Monitor
- [ ] Backup strategy implemented
- [ ] Security best practices reviewed
- [ ] Cost monitoring enabled
- [ ] Documentation updated

### Next Steps
- **Implement custom domain** with Azure DNS
- **Add SSL certificate** with Azure Application Gateway
- **Set up staging environment** for testing
- **Implement blue-green deployments**
- **Add comprehensive testing** suite
- **Consider migration to AKS** for production scale

**Happy Learning and Happy Deploying! 🚀**

## 🛠️ Author & Community  

This project is crafted by **[Harshhaa](https://github.com/NotHarshhaa)** 💡 and migrated to Azure by **[Rishizan](https://github.com/Rishizan)**.
I'd love to hear your feedback! Feel free to share your thoughts.  

📧 **Connect with me:**

- **GitHub**: [@Rishizan](https://github.com/Rishizan)  
- **Original Author**: [@NotHarshhaa](https://github.com/NotHarshhaa)  
- **Blog**: [ProDevOpsGuy](https://blog.prodevopsguytech.com)  

---

## ⭐ Support the Project  

If you found this helpful, consider **starring** ⭐ the repository and sharing it with your network! 🚀  

### 📢 Stay Connected  

![Follow Me](https://imgur.com/2j7GSPs.png)
