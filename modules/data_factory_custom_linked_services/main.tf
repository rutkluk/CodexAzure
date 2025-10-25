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
  for_each = local.normalized_linked_services

  name                 = each.value.name
  data_factory_id      = var.data_factory_id
  type                 = each.value.type
  type_properties_json = each.value.type_properties_json

  annotations             = each.value.annotations
  additional_properties   = each.value.additional_properties
  parameters              = each.value.parameters
  integration_runtime_name = each.value.integration_runtime_name
}
