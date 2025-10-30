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
  source = "../../components/data_factory/default"

  factory_name        = "df-system-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"
  environment         = "test"

  subnet = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.10.1.0/24"
  }

  subnet_pe = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.10.2.0/24"
  }

  identity = {
    type = "SystemAssigned"
  }

  tags = {
    environment = "test"
    scenario    = "system-only"
  }
}
