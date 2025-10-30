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

module "uami" {
  source = "../../modules/user_assigned_identity"

  name                = "uami-adf-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"

  role_assignments = [
    {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo"
      role_definition_name = "Reader"
    },
    {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
      role_definition_name = "Key Vault Secrets User"
    }
  ]

  tags = {
    environment = "dev"
  }
}

module "data_factory" {
  source = "../../components/data_factory/default"

  factory_name        = "df-user-assigned-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "dev"

  subnet = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.20.1.0/24"
  }

  subnet_pe = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.20.2.0/24"
  }

  identity = {
    type                       = "UserAssigned"
    user_assigned_identity_ids = [module.uami.id]
  }

  tags = {
    environment = "dev"
    scenario    = "user-assigned-only"
  }
}
