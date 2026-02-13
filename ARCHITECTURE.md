# Architecture Documentation

This document describes the architecture of the Django application deployment on Microsoft Azure.

## Overview

This project implements a cloud-native Django application deployment using Azure Container Registry (ACR) and Azure Container Instances (ACI), with Infrastructure as Code (Terraform) and CI/CD automation (GitHub Actions).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Repository                        │
│                    (Source Code + Workflows)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ git push
                             ▼
                    ┌────────────────────┐
                    │  GitHub Actions    │
                    │   (CI/CD Pipeline) │
                    └─────────┬──────────┘
                              │
                              │ 1. Build Docker Image
                              │ 2. Push to ACR
                              │ 3. Deploy to ACI
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Cloud                               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Azure Container Registry (ACR)              │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────┐     │  │
│  │  │  Docker Images                                 │     │  │
│  │  │  - django-app:latest                          │     │  │
│  │  │  - django-app:v1.0.0                          │     │  │
│  │  │  - django-app:<git-sha>                       │     │  │
│  │  └────────────────────────────────────────────────┘     │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │                                     │
│                           │ Pull Image                          │
│                           ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │       Azure Container Instances (ACI)                    │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────┐     │  │
│  │  │  Django Container                              │     │  │
│  │  │  - CPU: 0.5-1 vCPU                            │     │  │
│  │  │  - Memory: 1.5 GB                             │     │  │
│  │  │  - Port: 8000                                 │     │  │
│  │  │  - Gunicorn WSGI Server                       │     │  │
│  │  └────────────────────────────────────────────────┘     │  │
│  │                                                          │  │
│  │  Public IP: <dynamic-ip>                                │  │
│  │  FQDN: <project-name>.eastus.azurecontainer.io         │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │                                     │
│  ┌────────────────────────▼─────────────────────────────────┐  │
│  │         Azure Monitor (Optional)                         │  │
│  │  - Container Logs                                        │  │
│  │  - Metrics (CPU, Memory, Network)                        │  │
│  │  - Alerts                                                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTP/HTTPS
                              ▼
                      ┌───────────────┐
                      │  End Users    │
                      └───────────────┘
```

## Components

### 1. Django Application

**Technology**: Python 3.9 + Django Framework

**Purpose**: Web application serving HTTP requests

**Key Features**:
- WSGI application served by Gunicorn
- Static files handled by WhiteNoise
- SQLite database (for demo; use Azure Database for production)
- Health check endpoint

**Configuration**:
- Environment variables for settings
- Production-ready security settings
- Static files collection

### 2. Docker Container

**Base Image**: `python:3.9-slim`

**Build Strategy**: Multi-stage build
- Stage 1: Build dependencies
- Stage 2: Production runtime

**Security**:
- Non-root user (`appuser`)
- Minimal attack surface
- No unnecessary packages

**Exposed Port**: 8000

### 3. Azure Container Registry (ACR)

**SKU**: Basic (configurable to Standard/Premium)

**Purpose**: Private Docker image registry

**Features**:
- Secure image storage
- Admin authentication (dev) or managed identity (prod)
- Image scanning (Standard/Premium)
- Geo-replication (Premium)

**Naming**: `<project-name>.azurecr.io`

### 4. Azure Container Instances (ACI)

**Purpose**: Serverless container hosting

**Configuration**:
- **CPU**: 0.5-1 vCPU (configurable)
- **Memory**: 1.5 GB (configurable)
- **OS**: Linux
- **Networking**: Public IP with DNS label
- **Restart Policy**: Always

**Benefits**:
- Fast startup (seconds)
- Per-second billing
- No infrastructure management
- Hypervisor-level isolation

### 5. Infrastructure as Code (Terraform)

**Provider**: Azure (azurerm)

**Resources Managed**:
- Resource Group
- Azure Container Registry
- Azure Container Instances

**Variables**:
- `location`: Azure region (default: East US)
- `project_name`: Project identifier (default: devopsproj04)

**Outputs**:
- ACR login server
- ACI public IP
- ACI FQDN

### 6. CI/CD Pipeline (GitHub Actions)

**Trigger**: Push to `master` branch

**Workflow Steps**:
1. Checkout code
2. Login to Azure
3. Login to ACR
4. Build Docker image
5. Tag image (git SHA + latest)
6. Push to ACR
7. Deploy to ACI

**Secrets Required**:
- `AZURE_CREDENTIALS`: Service principal JSON

## Data Flow

### Deployment Flow

1. **Developer** commits code to GitHub
2. **GitHub Actions** triggers on push to master
3. **Workflow** builds Docker image from Dockerfile
4. **Image** is tagged with git SHA and `latest`
5. **Image** is pushed to Azure Container Registry
6. **ACI** pulls the new image from ACR
7. **Container** starts and serves the application
8. **Users** access via public FQDN

### Request Flow

1. **User** sends HTTP request to `http://<fqdn>:8000`
2. **Azure** routes to Container Instance public IP
3. **Gunicorn** receives request on port 8000
4. **Django** processes request
5. **Response** sent back to user

## Scalability Considerations

### Current Architecture (ACI)

**Pros**:
- Simple and cost-effective
- Fast deployment
- No infrastructure management

**Cons**:
- Manual scaling only
- Single instance (no built-in HA)
- Limited to one container per group

### Scaling Options

#### Horizontal Scaling
For production workloads, consider:

1. **Azure Kubernetes Service (AKS)**
   - Auto-scaling (HPA, VPA, Cluster Autoscaler)
   - Load balancing
   - Rolling updates
   - High availability

2. **Azure App Service**
   - Built-in auto-scaling
   - Deployment slots
   - Easy SSL/custom domains

#### Vertical Scaling
- Increase CPU/memory in ACI
- Update Terraform variables
- Redeploy with `terraform apply`

## Security Architecture

### Network Security

**Current**: Public IP with open port 8000

**Production Recommendations**:
- Use Azure Virtual Network integration
- Implement Network Security Groups (NSG)
- Add Azure Application Gateway with WAF
- Enable HTTPS with SSL/TLS

### Authentication & Authorization

**ACR Access**:
- Development: Admin user credentials
- Production: Managed Identity or Service Principal

**Container Access**:
- Environment variables for configuration
- Azure Key Vault for secrets (recommended)

### Container Security

- Non-root user in container
- Minimal base image
- Regular image scanning
- Immutable tags for production

## Monitoring & Observability

### Logging

**Container Logs**:
```bash
az container logs --resource-group <rg> --name <container>
```

**Azure Monitor Integration** (Optional):
- Log Analytics workspace
- Container Insights
- Custom metrics

### Metrics

**Available Metrics**:
- CPU usage
- Memory usage
- Network bytes in/out
- Container restart count

### Health Checks

**Application**: `/health/` endpoint

**Container**: Azure monitors container state

## Cost Structure

### Monthly Cost Estimate (East US)

| Resource | Configuration | Estimated Cost |
|----------|--------------|----------------|
| ACR Basic | 10 GB storage | ~$5/month |
| ACI | 0.5 vCPU, 1.5 GB, 24/7 | ~$20-25/month |
| **Total** | | **~$25-30/month** |

### Cost Optimization

- Stop ACI when not in use (dev/test)
- Use Azure Reservations for predictable workloads
- Implement image lifecycle policies in ACR
- Right-size container resources

## Disaster Recovery

### Backup Strategy

**Code**: Version controlled in GitHub

**Container Images**: Stored in ACR with versioning

**Data**: 
- SQLite (ephemeral - not recommended for production)
- Use Azure Database for persistent data

### Recovery Procedures

**Complete Failure**:
1. Run `terraform apply` to recreate infrastructure
2. GitHub Actions will redeploy on next push
3. Or manually push image and restart container

**RTO**: ~5-10 minutes
**RPO**: Last committed code

## Production Recommendations

For production deployments, consider:

1. **Database**: Azure Database for PostgreSQL/MySQL
2. **Static Files**: Azure Blob Storage + CDN
3. **Caching**: Azure Cache for Redis
4. **Secrets**: Azure Key Vault
5. **SSL/TLS**: Azure Application Gateway or Front Door
6. **Monitoring**: Application Insights
7. **Orchestration**: Azure Kubernetes Service (AKS)
8. **Backup**: Automated backup strategies

## Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| Application | Django 4.x, Python 3.9 |
| Web Server | Gunicorn |
| Containerization | Docker |
| Container Registry | Azure Container Registry |
| Container Hosting | Azure Container Instances |
| Infrastructure as Code | Terraform |
| CI/CD | GitHub Actions |
| Monitoring | Azure Monitor (optional) |
| Cloud Provider | Microsoft Azure |

## References

- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure Container Instances Documentation](https://docs.microsoft.com/en-us/azure/container-instances/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
