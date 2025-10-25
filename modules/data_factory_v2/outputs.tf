output "data_factory_id" {
  description = "The ID of the created Azure Data Factory."
  value       = azurerm_data_factory.this.id
}

output "data_factory_name" {
  description = "The name of the created Azure Data Factory."
  value       = azurerm_data_factory.this.name
}

output "managed_virtual_network_enabled" {
  description = "Indicates whether Managed Virtual Network is enabled."
  value       = azurerm_data_factory.this.managed_virtual_network_enabled
}

output "public_network_enabled" {
  description = "Indicates whether public network access is enabled."
  value       = azurerm_data_factory.this.public_network_enabled
}

output "identity_type" {
  description = "The effective managed identity type configured on the Data Factory."
  value       = try(azurerm_data_factory.this.identity[0].type, null)
}

output "identity_principal_id" {
  description = "The principal ID of the system-assigned identity, if enabled."
  value       = try(azurerm_data_factory.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "The tenant ID associated with the Data Factory's managed identity."
  value       = try(azurerm_data_factory.this.identity[0].tenant_id, null)
}

output "identity_user_assigned_ids" {
  description = "List of user-assigned managed identity IDs attached to the Data Factory."
  value       = try(azurerm_data_factory.this.identity[0].identity_ids, null)
}
