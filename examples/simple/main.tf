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

  customer_managed_key_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo/keys/key-demo"

  tags = {
    environment = "pre"
    component   = "data-factory"
  }
}

module "integration_runtimes" {
  source = "../../modules/data_factory_integration_runtimes"

  data_factory_id         = module.data_factory.data_factory_id
  default_azure_location  = "westeurope"
  integration_runtimes = {
    defaultAzure = {
      type                  = "azure"
      description           = "Primary Azure IR for region-bound activities"
      compute_type          = "General"
      core_count            = 16
      time_to_live          = 10
      virtual_network_enabled = true
    }

    selfHostedHub = {
      type        = "self_hosted"
      description = "Self-hosted runtime for on-premises connectivity"
    }
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
