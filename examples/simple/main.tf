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

  factory_name        = "df-demo-001"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "pre"

  identity = {
    enable_system_assigned_identity = true
    user_assigned_identity_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/example"
    ]
  }

  customer_managed_key_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo/keys/key-demo/1234567890"

  tags = {
    environment = "pre"
    component   = "data-factory"
  }
}

module "custom_linked_services" {
  source = "../../modules/data_factory_custom_linked_services"

  data_factory_id = module.data_factory.data_factory_id

  linked_services = {
    demoBlob = {
      type = "AzureBlobStorage"
      type_properties_json = jsonencode({
        connectionString = "DefaultEndpointsProtocol=https;AccountName=example;AccountKey=example;EndpointSuffix=core.windows.net"
      })
      annotations = ["example"]
    }
  }
}
