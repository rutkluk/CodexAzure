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

resource "azurerm_data_factory_pipeline" "this" {
  for_each = local.pipelines_with_source

  name            = each.value.name
  data_factory_id = var.data_factory_id
  activities_json = each.value.resolved_json

  annotations = each.value.annotations
  folder      = each.value.folder
  parameters  = each.value.parameters
  variables   = each.value.variables
  # additional_properties not supported in azurerm 4.37.0

  lifecycle {
    precondition {
      condition     = each.value.resolved_json != null
      error_message = "Pipeline definition must provide either `activities_json` or `file_path` with valid JSON content."
    }
  }
}
