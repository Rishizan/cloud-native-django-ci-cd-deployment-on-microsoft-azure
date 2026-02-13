# Deployment Guide

This guide provides step-by-step instructions for deploying the Django application to Azure.

## Prerequisites

Before you begin, ensure you have:

- ✅ Azure account with an active subscription
- ✅ Azure CLI installed ([Install Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- ✅ Docker installed ([Install Guide](https://docs.docker.com/get-docker/))
- ✅ Git installed
- ✅ (Optional) Terraform installed for IaC deployment

## Deployment Options

You can deploy this application using either:
1. **Terraform** (Recommended - Infrastructure as Code)
2. **Azure CLI** (Manual deployment)
3. **GitHub Actions** (CI/CD automation)

---

## Option 1: Terraform Deployment (Recommended)

### Step 1: Clone the Repository

```bash
git clone https://github.com/Rishizan/cloud-native-django-ci-cd-deployment-on-microsoft-azure.git
cd cloud-native-django-ci-cd-deployment-on-microsoft-azure
```

### Step 2: Login to Azure

```bash
az login
```

### Step 3: Customize Variables (Optional)

Edit `terraform/variables.tf` or create `terraform/terraform.tfvars`:

```hcl
location     = "East US"
project_name = "mydjango"
```

### Step 4: Initialize and Deploy Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted to confirm.

### Step 5: Get Deployment Outputs

```bash
# Get ACR login server
terraform output acr_login_server

# Get ACI FQDN
terraform output aci_fqdn
```

### Step 6: Build and Push Docker Image

```bash
# Get ACR name
ACR_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push from project root
cd ..
docker build -t $ACR_NAME.azurecr.io/devopsproj04:latest .
docker push $ACR_NAME.azurecr.io/devopsproj04:latest
```

### Step 7: Restart Container Instance

```bash
# Get resource group name
RG_NAME=$(terraform output -raw acr_login_server | cut -d'.' -f1)-rg

# Restart container to pull latest image
az container restart --resource-group $RG_NAME --name devopsproj04-aci
```

### Step 8: Access Your Application

```bash
# Get the application URL
FQDN=$(terraform output -raw aci_fqdn)
echo "Application URL: http://$FQDN:8000"
```

Open the URL in your browser!

---

## Option 2: Manual Azure CLI Deployment

### Step 1: Create Resource Group

```bash
az group create \
    --name django-app-rg \
    --location eastus
```

### Step 2: Create Azure Container Registry

```bash
az acr create \
    --resource-group django-app-rg \
    --name mydjangoacr \
    --sku Basic \
    --admin-enabled true
```

### Step 3: Build and Push Image

```bash
# Login to ACR
az acr login --name mydjangoacr

# Build image in ACR (recommended)
az acr build \
    --registry mydjangoacr \
    --image django-app:latest \
    --file Dockerfile .

# Or build locally and push
docker build -t mydjangoacr.azurecr.io/django-app:latest .
docker push mydjangoacr.azurecr.io/django-app:latest
```

### Step 4: Get ACR Credentials

```bash
ACR_USERNAME=$(az acr credential show --name mydjangoacr --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name mydjangoacr --query passwords[0].value -o tsv)
```

### Step 5: Deploy to Azure Container Instances

```bash
az container create \
    --resource-group django-app-rg \
    --name django-aci \
    --image mydjangoacr.azurecr.io/django-app:latest \
    --cpu 1 \
    --memory 1.5 \
    --registry-login-server mydjangoacr.azurecr.io \
    --registry-username $ACR_USERNAME \
    --registry-password $ACR_PASSWORD \
    --dns-name-label django-app-$(date +%s) \
    --ports 8000 \
    --environment-variables DJANGO_SETTINGS_MODULE=hello_world_django_app.settings
```

### Step 6: Get Application URL

```bash
az container show \
    --resource-group django-app-rg \
    --name django-aci \
    --query ipAddress.fqdn \
    --output tsv
```

---

## Option 3: GitHub Actions CI/CD

### Step 1: Fork the Repository

Fork this repository to your GitHub account.

### Step 2: Create Azure Resources

Use either Terraform or Azure CLI to create:
- Resource Group
- Azure Container Registry
- (Optional) Container Instance

### Step 3: Create Service Principal

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
    --name "github-actions-sp" \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/devopsproj04-rg \
    --sdk-auth
```

Copy the entire JSON output.

### Step 4: Add GitHub Secret

1. Go to your forked repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the JSON from Step 3
6. Click **Add secret**

### Step 5: Update Workflow Variables

Edit `.github/workflows/deploy.yml` if needed to match your resource names.

### Step 6: Trigger Deployment

```bash
git add .
git commit -m "Deploy to Azure"
git push origin master
```

The GitHub Actions workflow will automatically:
1. Build the Docker image
2. Push to ACR
3. Deploy to ACI

### Step 7: Monitor Deployment

1. Go to the **Actions** tab in your GitHub repository
2. Click on the latest workflow run
3. Monitor the progress

---

## Post-Deployment Steps

### Verify Deployment

```bash
# Check container status
az container show \
    --resource-group <your-rg> \
    --name <your-container> \
    --query instanceView.state

# View logs
az container logs \
    --resource-group <your-rg> \
    --name <your-container>
```

### Configure Custom Domain (Optional)

For production, you may want to:
1. Use Azure Application Gateway or Azure Front Door
2. Configure custom domain
3. Add SSL/TLS certificate

### Enable Monitoring (Optional)

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
    --resource-group django-app-rg \
    --workspace-name django-logs

# Update container with logging
# (requires container recreation)
```

---

## Updating Your Application

### Update Code and Redeploy

```bash
# Make your code changes
git add .
git commit -m "Update application"

# Rebuild and push image
az acr build --registry <acr-name> --image django-app:latest .

# Restart container
az container restart --resource-group <rg-name> --name <container-name>
```

---

## Cleanup

### Using Terraform

```bash
cd terraform
terraform destroy
```

### Using Azure CLI

```bash
# Delete resource group (deletes all resources)
az group delete --name django-app-rg --yes --no-wait
```

---

## Troubleshooting

### Container Won't Start

```bash
# Check events
az container show \
    --resource-group <rg-name> \
    --name <container-name> \
    --query instanceView.events

# Check logs
az container logs \
    --resource-group <rg-name> \
    --name <container-name>
```

### Image Pull Errors

```bash
# Verify ACR credentials
az acr credential show --name <acr-name>

# Test ACR login
az acr login --name <acr-name>
```

### Can't Access Application

```bash
# Verify container is running
az container show \
    --resource-group <rg-name> \
    --name <container-name> \
    --query instanceView.state

# Check IP address and ports
az container show \
    --resource-group <rg-name> \
    --name <container-name> \
    --query ipAddress
```

---

## Support

For issues or questions:
- Check the [README.md](README.md) for detailed documentation
- Review [ARCHITECTURE.md](ARCHITECTURE.md) for system design
- Open an issue on GitHub
