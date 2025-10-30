output "managed_private_endpoint_ids" {
  description = "Map of keys to managed private endpoint resource IDs."
  value       = { for k, v in azurerm_data_factory_managed_private_endpoint.this : k => v.id }
}

output "managed_private_endpoint_names" {
  description = "Map of keys to managed private endpoint names."
  value       = { for k, v in azurerm_data_factory_managed_private_endpoint.this : k => v.name }
}

