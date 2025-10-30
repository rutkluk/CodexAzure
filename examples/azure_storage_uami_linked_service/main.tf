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

# This standalone example showcases creating an Azure Blob Storage
# linked service that authenticates with a user-assigned managed identity.
module "storage_linked_service" {
  source = "../../components/data_factory/modules/custom_linked_services"

  data_factory_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.DataFactory/factories/df-demo"

  linked_services = {
    storage = {
      type = "AzureBlobStorage"
      type_properties_json = jsonencode({
        serviceEndpoint           = "https://stexample.blob.core.windows.net/"
        authenticationType        = "ManagedIdentity"
        managedIdentityResourceId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-demo"
      })
      annotations = [
        "storage",
        "user-assigned-mi",
      ]
    }
  }
}
