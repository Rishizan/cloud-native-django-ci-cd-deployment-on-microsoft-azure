output "acr_login_server" {
  description = "The login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "aci_public_ip" {
  description = "The public IP address of the Container Instance"
  value       = azurerm_container_group.aci.ip_address
}

output "aci_fqdn" {
  description = "The FQDN of the Container Instance"
  value       = azurerm_container_group.aci.fqdn
}
