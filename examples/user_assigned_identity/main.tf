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

module "data_factory" {
  source = "../../modules/data_factory_v2"

  factory_name        = "df-user-assigned-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "dev"

  identity = {
    type = "UserAssigned"
    user_assigned_identity_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/example"
    ]
  }

  tags = {
    environment = "dev"
    scenario    = "user-assigned-only"
  }
}
