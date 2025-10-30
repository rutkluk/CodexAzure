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
  normalized_endpoints = {
    for key, ep in var.endpoints : key => {
      name               = coalesce(try(ep.name, null), key)
      target_resource_id = trimspace(ep.target_resource_id)
      subresource_name   = trimspace(ep.subresource_name)
      description        = try(ep.description, null)
    }
  }
}

resource "azurerm_data_factory_managed_private_endpoint" "this" {
  for_each = local.normalized_endpoints

  name               = each.value.name
  data_factory_id    = var.data_factory_id
  target_resource_id = each.value.target_resource_id
  subresource_name   = each.value.subresource_name
}
