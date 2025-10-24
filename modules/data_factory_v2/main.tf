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

locals {
  identity_type_tokens = var.identity == null ? [] : split(",", replace(var.identity.type, " ", ""))
  identity_requires_user_assigned_ids = length([
    for token in local.identity_type_tokens : lower(token)
    if token != "" && token == "userassigned"
  ]) > 0
  identity_user_assigned_identity_ids = var.identity == null ? null : lookup(var.identity, "user_assigned_identity_ids", null)

  customer_managed_key_supplied = var.customer_managed_key_id != null && trimspace(var.customer_managed_key_id) != ""
  use_customer_managed_key       = local.customer_managed_key_supplied || contains(["pre", "prod"], lower(var.environment))
}

resource "azurerm_data_factory" "this" {
  name                = var.factory_name
  location            = var.location
  resource_group_name = var.resource_group_name

  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  public_network_enabled          = var.public_network_enabled

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = local.identity_requires_user_assigned_ids ? local.identity_user_assigned_identity_ids : null
    }
  }

  dynamic "github_configuration" {
    for_each = var.github_configuration == null ? [] : [var.github_configuration]
    content {
      account_name    = github_configuration.value.account_name
      branch_name     = github_configuration.value.branch_name
      git_url         = github_configuration.value.git_url
      repository_name = github_configuration.value.repository_name
      root_folder     = lookup(github_configuration.value, "root_folder", null)
    }
  }

  customer_managed_key_id = local.use_customer_managed_key ? var.customer_managed_key_id : null

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !(contains(["pre", "prod"], lower(var.environment)) && !local.customer_managed_key_supplied)
      error_message = "customer_managed_key_id must be provided when environment is pre or prod."
    }
  }
}
