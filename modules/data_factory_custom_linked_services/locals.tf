locals {
  normalized_linked_services = {
    for key, value in var.linked_services :
    key => merge(value, {
      name                    = coalesce(try(value.name, null), key)
      annotations             = try(value.annotations, null)
      additional_properties   = try(value.additional_properties, null)
      parameters              = try(value.parameters, null)
      integration_runtime_name = try(value.integration_runtime_name, null)
    })
  }

  linked_service_ids = {
    for _, service in azurerm_data_factory_linked_service.this :
    service.name => service.id
  }

  linked_service_names = [for _, service in azurerm_data_factory_linked_service.this : service.name]
}
