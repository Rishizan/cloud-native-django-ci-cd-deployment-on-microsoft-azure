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
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location
}

# --- Azure Container Registry (Basic Tier for Students) ---
resource "azurerm_container_registry" "acr" {
  name                = replace(var.project_name, "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

# --- Azure Container Instance (ACI) ---
resource "azurerm_container_group" "aci" {
  name                = "${var.project_name}-aci"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Public"
  dns_name_label      = var.project_name
  os_type             = "Linux"

  container {
    name   = var.project_name
    image  = "${azurerm_container_registry.acr.login_server}/${var.project_name}:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 8000
      protocol = "TCP"
    }

    # Environment variables can be added here
    environment_variables = {
      "DJANGO_SETTINGS_MODULE" = "hello_world_django_app.settings"
    }
  }

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }

  tags = {
    environment = "student"
  }
}
