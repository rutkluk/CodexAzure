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

resource "azurerm_data_factory_credential_user_managed_identity" "uami" {
  for_each = local.normalized_uami_credentials

  name            = each.value.name
  data_factory_id = var.data_factory_id
  identity_id     = each.value.identity_id
  annotations     = each.value.annotations
}

