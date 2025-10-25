locals {
  normalized_integration_runtimes = {
    for key, value in var.integration_runtimes :
    key => merge(value, {
      type = lower(value.type)
      name = coalesce(try(value.name, null), key)
    })
  }

  azure_integration_runtimes = {
    for key, value in local.normalized_integration_runtimes :
    key => value if value.type == "azure"
  }

  self_hosted_integration_runtimes = {
    for key, value in local.normalized_integration_runtimes :
    key => value if value.type == "self_hosted"
  }

  integration_runtime_ids_azure = {
    for key, value in azurerm_data_factory_integration_runtime_azure.this :
    key => value.id
  }

  integration_runtime_ids_self_hosted = {
    for key, value in azurerm_data_factory_integration_runtime_self_hosted.this :
    key => value.id
  }

  integration_runtime_names_all = [
    for runtime in concat(
      values(azurerm_data_factory_integration_runtime_azure.this),
      values(azurerm_data_factory_integration_runtime_self_hosted.this)
    ) : runtime.name
  ]
}
