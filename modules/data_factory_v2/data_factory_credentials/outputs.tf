output "credential_ids" {
  description = "Map of credential keys to their resource IDs."
  value       = { for k, v in azurerm_data_factory_credential_user_managed_identity.uami : k => v.id }
}

output "credential_names" {
  description = "Map of credential keys to their names."
  value       = { for k, v in azurerm_data_factory_credential_user_managed_identity.uami : k => v.name }
}

