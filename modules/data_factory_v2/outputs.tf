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
