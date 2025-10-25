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
  identity_config = var.identity == null ? null : {
    enable_system_assigned_identity = try(var.identity.enable_system_assigned_identity, false)
    user_assigned_identity_ids      = try(var.identity.user_assigned_identity_ids, [])
  }

  identity_type_tokens = local.identity_config == null ? [] : compact([
    local.identity_config.enable_system_assigned_identity ? "SystemAssigned" : null,
    length(local.identity_config.user_assigned_identity_ids) > 0 ? "UserAssigned" : null,
  ])

  identity_type = length(local.identity_type_tokens) == 0 ? null : join(", ", local.identity_type_tokens)

  identity_user_assigned_identity_ids = local.identity_config == null ? [] : local.identity_config.user_assigned_identity_ids
  use_system_assigned_identity        = contains(local.identity_type_tokens, "SystemAssigned")
  use_user_assigned_identity          = contains(local.identity_type_tokens, "UserAssigned")

  customer_managed_key_supplied = var.customer_managed_key_id != null && trimspace(var.customer_managed_key_id) != ""
  use_customer_managed_key       = local.customer_managed_key_supplied || contains(["pre", "prod"], lower(var.environment))

  customer_managed_key_input = !local.use_customer_managed_key ? null : trimspace(var.customer_managed_key_id)
  customer_managed_key_sanitized = local.customer_managed_key_input == null
    ? null
    : trimsuffix(local.customer_managed_key_input, "/")

  customer_managed_key_versionless_id = local.customer_managed_key_sanitized == null
    ? null
    : (
      can(regex("/keys/[^/]+/[^/]+$", local.customer_managed_key_sanitized))
      ? replace(local.customer_managed_key_sanitized, "/[^/]+$", "")
      : local.customer_managed_key_sanitized
    )

  customer_managed_key_identity_type = !local.use_customer_managed_key ? null : (
    local.use_system_assigned_identity ? "SystemAssigned" : (
      local.use_user_assigned_identity ? "UserAssigned" : null
    )
  )

  customer_managed_key_identity_id = local.customer_managed_key_identity_type == "UserAssigned" && length(local.identity_user_assigned_identity_ids) > 0
    ? local.identity_user_assigned_identity_ids[0]
    : null
}


resource "azurerm_subnet" "subnet" {
  name = local.subnet_pe_name
  resource_group_name = var.subnet.resource_group_name
  virtual_network_name = var.subnet.vnet_name
  address_prefixes = [var.subnet.cidr]
  }

resource "azurerm_subnet" "subnet_pe" {
  name = local.subnet_name
  resource_group_name = var.subnet_pe.resource_group_name
  virtual_network_name = var.subnet_pe.vnet_name
  address_prefixes = [var.subnet_pe.cidr]
}

resource "azurerm_network_security_group" "nsg" {
  name = local.nsg.name
  location = var.location
  resource_group_name = var.resource_group_name
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc" {
  subnet_id = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc_pe" {
  subnet_id = azurerm_subnet.subnet_pe.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_rule" "default" {
 name = "DenyAll"
 protocol = "*"
 access = ""
 network_security_group_name = azureem_network_security_group.nsg.name
 direction = "Inbound"
 resource_group_name = var.resource_group_name
priority = 4000

}


resource "azurerm_key_vault_key" "cmk" {
  count = (var.environment == "prod" || var.environment == "pre") ? 1 : 0
  key_type = "RSA"
  key_size = 2048
  key_vault_id = var.key_vault_id
  name ="cmk"
  key_opts = [
    "unwrapKey",
    "wrapKey",
    "decrypt"
  ]
  expiration_date = timeadd(timestamp(), "2160h")
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after = "P90D"
    notify_before_expiry = "P29D"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [ 
      expiration_date,
      key_opts
     ]
  }
  tags = local.tags
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

  dynamic "global_parameter" {
    for_each = var.global_parameter
    content {
      name = global_parameter.value.name
      value = global_parameter.value.value
      type = global_parameter.value.type
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
    ignore_changes = [ 
      global_parameter,
      github_configuration
     ]
  }

}

resource "azurerm_data_factory_integration_runtime_azure" "default" {
  name = "AutoResolveIntegrationRuntime"
  data_factory_id = azurerm_data_factory.this.id
  location = "AutoResolve"
  virtual_network_enabled = true
}