output "linked_service_ids" {
  description = "Map of linked service names to their resource IDs."
  value = {
    for _, service in azurerm_data_factory_linked_service.this : service.name => service.id
  }
}

output "linked_service_names" {
  description = "List of linked service names managed by this module."
  value       = [for _, service in azurerm_data_factory_linked_service.this : service.name]
}
