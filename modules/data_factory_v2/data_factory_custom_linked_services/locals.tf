locals {
  normalized_linked_services = {
    for key, value in var.linked_services :
    key => merge(value, {
      name                     = coalesce(try(value.name, null), key)
      annotations              = try(value.annotations, null)
      additional_properties    = try(value.additional_properties, null)
      parameters               = try(value.parameters, null)
      integration_runtime_name = try(value.integration_runtime_name, null)
    })
  }

  # With azurerm v4.37.0, generic linked service resources are not available.
  # This submodule acts as a pass-through for names until specific types are added.
  linked_service_ids   = {}
  linked_service_names = [for _, svc in local.normalized_linked_services : svc.name]
}

