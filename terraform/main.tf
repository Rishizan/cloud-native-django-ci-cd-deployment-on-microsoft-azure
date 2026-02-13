terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Resource Group ---
# Creates a logical container for all Azure resources
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location
  
  tags = {
    environment = "development"
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# --- Azure Container Registry (ACR) ---
# Private Docker registry for storing container images
# Basic tier is cost-effective for development/learning
# Consider Standard or Premium for production workloads
resource "azurerm_container_registry" "acr" {
  name                = replace(var.project_name, "-", "")  # ACR names cannot contain hyphens
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"  # Options: Basic, Standard, Premium
  admin_enabled       = true     # Enable admin user for development (use managed identity in production)
  
  tags = {
    environment = "development"
    project     = var.project_name
  }
}

# --- Azure Container Instance (ACI) ---
# Serverless container hosting service
# Provides fast startup and per-second billing
resource "azurerm_container_group" "aci" {
  name                = "${var.project_name}-aci"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"           # Assigns a public IP address
  dns_name_label      = var.project_name   # Creates FQDN: <project_name>.<region>.azurecontainer.io
  os_type             = "Linux"

  # Container configuration
  container {
    name   = var.project_name
    image  = "${azurerm_container_registry.acr.login_server}/${var.project_name}:latest"
    cpu    = "0.5"   # vCPU cores (0.5-4)
    memory = "1.5"   # GB of memory (0.5-16)

    # Expose port 8000 for Django application
    ports {
      port     = 8000
      protocol = "TCP"
    }

    # Environment variables for Django configuration
    environment_variables = {
      "DJANGO_SETTINGS_MODULE" = "hello_world_django_app.settings"
      # Add more environment variables as needed:
      # "DEBUG" = "False"
      # "ALLOWED_HOSTS" = "*"
    }
    
    # For sensitive data, use secure_environment_variables instead:
    # secure_environment_variables = {
    #   "SECRET_KEY" = "your-secret-key"
    # }
  }

  # ACR authentication credentials
  # Uses admin credentials for simplicity (development)
  # For production, consider using managed identity
  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  tags = {
    environment = "development"
    project     = var.project_name
  }
}
