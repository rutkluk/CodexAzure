locals {
  azure_runtime_ids = {
    for key, value in azurerm_data_factory_integration_runtime_azure.this :
    key => value.id
  }

  self_hosted_runtime_ids = {
    for key, value in azurerm_data_factory_integration_runtime_self_hosted.this :
    key => value.id
  }
}

output "integration_runtime_ids" {
  description = "Map of integration runtime keys to their resource IDs."
  value       = merge(local.azure_runtime_ids, local.self_hosted_runtime_ids)
}

output "integration_runtime_names" {
  description = "List of integration runtime names managed by this module."
  value = [
    for runtime in concat(
      values(azurerm_data_factory_integration_runtime_azure.this),
      values(azurerm_data_factory_integration_runtime_self_hosted.this)
    ) : runtime.name
  ]
}
