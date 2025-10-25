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

# This standalone example illustrates how to configure a SQL Database
# linked service that retrieves its SQL authentication username and
# password from Azure Key Vault secrets.
module "mssql_linked_service" {
  source = "../../modules/data_factory_custom_linked_services"

  data_factory_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.DataFactory/factories/df-demo"

  linked_services = {
    mssql = {
      type = "AzureSqlDatabase"
      type_properties_json = jsonencode({
        connectionString   = "Server=tcp:sql-demo.database.windows.net,1433;Initial Catalog=db-demo;User ID=@{linkedService().username};Password=@{linkedService().password};"
        authenticationType = "SqlAuth"
        username = {
          type  = "SecureString"
          value = "@Microsoft.KeyVault(SecretUri=https://kv-demo.vault.azure.net/secrets/sql-username/)"
        }
        password = {
          type  = "SecureString"
          value = "@Microsoft.KeyVault(SecretUri=https://kv-demo.vault.azure.net/secrets/sql-password/)"
        }
      })
      annotations = [
        "mssql",
        "key-vault",
      ]
    }
  }
}
