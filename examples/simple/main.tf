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

  name                = "uami-df-demo-001"
  resource_group_name = "rg-demo"
  location            = "westeurope"

  role_assignments = [
    {
      scope                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo"
      role_definition_name = "Reader"
    }
  ]

  tags = {
    environment = "pre"
  }
}

module "data_factory" {
  source = "../../modules/data_factory_v2"

  factory_name        = "df-demo-001"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "pre"

  subnet = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.0.1.0/24"
  }

  subnet_pe = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.0.2.0/24"
  }

  identity = {
    enable_system_assigned_identity  = true
    user_assigned_identity_ids       = [module.uami.id]
    customer_managed_key_identity_id = module.uami.id
  }

  customer_managed_key_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo/keys/key-demo"
  key_vault_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
  purview_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.Purview/accounts/purview-demo"

  global_parameters = {
    environment = {
      type  = "String"
      value = "pre"
    }

    processTimeout = {
      type  = "Float"
      value = "30"
    }
  }

  tags = {
    environment = "pre"
    component   = "data-factory"
  }
}

module "adf_credentials" {
  source = "../../modules/data_factory_credentials"

  data_factory_id = module.data_factory.data_factory_id

  credentials_uami = {
    uamiDefault = {
      identity_id = module.uami.id
      annotations = ["primary-uami"]
    }
  }
}

module "integration_runtimes" {
  source = "../../modules/data_factory_integration_runtimes"

  data_factory_id        = module.data_factory.data_factory_id
  default_azure_location = "westeurope"
  integration_runtimes = {
    defaultAzure = {
      type                    = "azure"
      description             = "Primary Azure IR for region-bound activities"
      compute_type            = "General"
      core_count              = 16
      time_to_live            = 10
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

module "pipeline_triggers" {
  source = "../../modules/data_factory_pipeline_triggers"

  data_factory_id = module.data_factory.data_factory_id

  triggers = {
    nightly = {
      type          = "schedule"
      pipeline_name = "pl-nightly-refresh"
      schedule = {
        frequency  = "Day"
        interval   = 1
        time_zone  = "UTC"
        hours      = [2]
        minutes    = [0]
        start_time = "2023-01-01T00:00:00Z"
      }
      annotations = ["nightly"]
    }

    hourly_window = {
      type          = "tumbling_window"
      pipeline_name = "pl-hourly-window"
      frequency     = "Hour"
      interval      = 1
      start_time    = "2023-01-01T00:00:00Z"
      delay         = "00:05:00"
      retry = {
        count               = 3
        interval_in_seconds = 120
      }
    }
  }
}
