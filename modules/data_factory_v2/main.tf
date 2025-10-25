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

resource "azurerm_data_factory" "this" {
  name                = var.factory_name
  location            = var.location
  resource_group_name = var.resource_group_name

  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  public_network_enabled          = var.public_network_enabled

  dynamic "identity" {
    for_each = local.identity_type == null ? [] : [1]
    content {
      type         = local.identity_type
      identity_ids = local.use_user_assigned_identity ? local.identity_user_assigned_identity_ids : null
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

  customer_managed_key_id = local.use_customer_managed_key ? local.customer_managed_key_versionless_id : null

  dynamic "customer_managed_key_identity" {
    for_each = local.use_customer_managed_key && local.customer_managed_key_identity_type != null ? [1] : []
    content {
      type                    = local.customer_managed_key_identity_type
      user_assigned_identity_id = local.customer_managed_key_identity_type == "UserAssigned" ? local.customer_managed_key_identity_id : null
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !(contains(["pre", "prod"], lower(var.environment)) && !local.customer_managed_key_supplied)
      error_message = "customer_managed_key_id must be provided when environment is pre or prod."
    }

    precondition {
      condition     = !local.use_customer_managed_key || local.identity_type != null
      error_message = "A managed identity must be configured when customer managed keys are enabled."
    }

    precondition {
      condition     = !local.use_customer_managed_key || local.customer_managed_key_versionless_id != null
      error_message = "customer_managed_key_id could not be normalized to a versionless key identifier."
    }

    precondition {
      condition     = !local.use_customer_managed_key || (local.customer_managed_key_versionless_id != null && can(regex("/keys/", local.customer_managed_key_versionless_id)))
      error_message = "customer_managed_key_id must reference an Azure Key Vault key."
    }
  }
}
