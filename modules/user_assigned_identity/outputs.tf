output "id" {
  description = "Resource ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Name of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "Azure AD object ID (principal) of the identity."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Client ID (application ID) of the identity."
  value       = azurerm_user_assigned_identity.this.client_id
}

