output "id" {
  description = "ID utworzonego Linked Service do Key Vault."
  value       = try(azurerm_data_factory_linked_service_key_vault.this[0].id, null)
}

output "name" {
  description = "Nazwa utworzonego Linked Service."
  value       = try(azurerm_data_factory_linked_service_key_vault.this[0].name, null)
}
