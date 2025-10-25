terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.37.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  normalized_runtimes = {
    for key, value in var.integration_runtimes :
    key => merge(value, {
      type = lower(value.type)
      name = coalesce(try(value.name, null), key)
    })
  }

  azure_runtimes = {
    for key, value in local.normalized_runtimes :
    key => value if value.type == "azure"
  }

  self_hosted_runtimes = {
    for key, value in local.normalized_runtimes :
    key => value if value.type == "self_hosted"
  }
}

resource "azurerm_data_factory_integration_runtime_azure" "this" {
  for_each = local.azure_runtimes

  name            = each.value.name
  data_factory_id = var.data_factory_id

  description             = try(each.value.description, null)
  location                = coalesce(try(each.value.location, null), var.default_azure_location)
  compute_type            = try(each.value.compute_type, null)
  core_count              = try(each.value.core_count, null)
  time_to_live            = try(each.value.time_to_live, null)
  virtual_network_enabled = try(each.value.virtual_network_enabled, null)

  lifecycle {
    precondition {
      condition     = location != null && trimspace(location) != ""
      error_message = "Azure integration runtimes require a location. Provide a per-runtime location or default_azure_location."
    }
  }
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "this" {
  for_each = local.self_hosted_runtimes

  name            = each.value.name
  data_factory_id = var.data_factory_id

  description = try(each.value.description, null)

  dynamic "rbac_authorization" {
    for_each = try(each.value.rbac_authorization, null) == null ? [] : [each.value.rbac_authorization]
    content {
      resource_id  = rbac_authorization.value.resource_id
      principal_id = rbac_authorization.value.principal_id
      tenant_id    = rbac_authorization.value.tenant_id
    }
  }
}
