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

resource "azurerm_data_factory_linked_service" "this" {
  for_each = var.linked_services

  name                 = coalesce(try(each.value.name, null), each.key)
  data_factory_id      = var.data_factory_id
  type                 = each.value.type
  type_properties_json = each.value.type_properties_json

  annotations           = try(each.value.annotations, null)
  additional_properties = try(each.value.additional_properties, null)
  parameters            = try(each.value.parameters, null)
  integration_runtime_name = try(each.value.integration_runtime_name, null)
}
