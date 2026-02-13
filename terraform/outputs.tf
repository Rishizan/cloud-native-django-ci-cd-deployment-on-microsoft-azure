output "acr_login_server" {
  description = "The login server URL for the Azure Container Registry (use for docker login and image tagging)"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Admin username for ACR (for development use only)"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "aci_public_ip" {
  description = "The public IP address of the Container Instance"
  value       = azurerm_container_group.aci.ip_address
}

output "aci_fqdn" {
  description = "The fully qualified domain name (FQDN) of the Container Instance - use this to access your application"
  value       = azurerm_container_group.aci.fqdn
}

output "application_url" {
  description = "Complete URL to access the Django application"
  value       = "http://${azurerm_container_group.aci.fqdn}:8000"
}
