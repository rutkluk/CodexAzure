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

resource "azurerm_data_factory_linked_service_key_vault" "this" {
  count           = var.enabled ? 1 : 0
  name            = var.name
  data_factory_id = var.data_factory_id
  key_vault_id    = var.key_vault_id

  annotations              = var.annotations
  parameters               = var.parameters
  integration_runtime_name = var.integration_runtime_name
}
