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

  name                = "uami-adf-combined"
  resource_group_name = "rg-demo"
  location            = "westeurope"

  role_assignments = [
    {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo"
      role_definition_name = "Reader"
    }
  ]

  tags = {
    environment = "prod"
  }
}

module "data_factory" {
  source = "../../components/data_factory/default"

  factory_name        = "df-combined-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "prod"

  subnet = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.30.1.0/24"
  }

  subnet_pe = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.30.2.0/24"
  }

  identity = {
    type                       = "SystemAssigned, UserAssigned"
    user_assigned_identity_ids = [module.uami.id]
  }

  customer_managed_key_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo/keys/key-demo"
  key_vault_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
  customer_managed_key_identity_id = module.uami.id

  tags = {
    environment = "prod"
    scenario    = "system-and-user"
  }
}
