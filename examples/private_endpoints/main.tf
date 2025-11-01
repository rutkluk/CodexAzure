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

# Example: Create a Managed Private Endpoint from ADF to Key Vault
module "adf_private_endpoints" {
  source = "../../components/data_factory/modules/private_endpoints"

  # Replace with your Data Factory resource ID
  data_factory_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.DataFactory/factories/df-demo"

  endpoints = {
    kv = {
      # Optional: defaults to the map key
      name = "mpe-kv-demo"
      # Replace with your Key Vault resource ID
      target_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
      # For Key Vault use the subresource name "vault"
      subresource_name = "vault"
      description      = "ADF MPE to Key Vault"
    }
  }
}

