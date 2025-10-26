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

# This example assumes the Data Factory already exists and focuses on
# illustrating how to configure a Dataverse linked service using the
# reusable custom linked services module.
module "dataverse_linked_service" {
  source = "../../modules/data_factory_v2/data_factory_custom_linked_services"

  data_factory_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.DataFactory/factories/df-demo"

  linked_services = {
    dataverse = {
      type = "Microsoft.Dataverse"
      type_properties_json = jsonencode({
        authenticationType             = "AADServicePrincipal"
        servicePrincipalCredentialType = "ServicePrincipalKey"
        servicePrincipalCredential = {
          type  = "SecureString"
          value = "@Microsoft.KeyVault(SecretUri=https://kv-demo.vault.azure.net/secrets/dataverse-client-secret/)"
        }
        servicePrincipalId = "11111111-1111-1111-1111-111111111111"
        tenant             = "22222222-2222-2222-2222-222222222222"
        serviceUri         = "https://org.crm4.dynamics.com"
        organizationName   = "org"
        deploymentType     = "Online"
      })
      annotations = [
        "dataverse",
        "service-principal"
      ]
    }
  }
}
