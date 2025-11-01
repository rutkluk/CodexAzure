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

resource "azurerm_data_factory_managed_private_endpoint" "this" {
  for_each = local.normalized_endpoints

  name               = each.value.name
  data_factory_id    = var.data_factory_id
  target_resource_id = each.value.target_resource_id
  subresource_name   = each.value.subresource_name
}
