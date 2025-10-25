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

  factory_name        = "df-system-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "test"

  identity = {
    enable_system_assigned_identity = true
  }

  tags = {
    environment = "test"
    scenario    = "system-only"
  }
}
