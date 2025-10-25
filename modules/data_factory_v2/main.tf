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

resource "azurerm_data_factory_integration_runtime_azure" "default" {
  name = "AutoResolveIntegrationRuntime"
  data_factory_id = azurerm_data_factory.this.id
  location = "AutoResolve"
  virtual_network_enabled = true
}

resource "azurerm_data_factory" "this" {
  name                = var.factory_name
  location            = var.location
  resource_group_name = var.resource_group_name

  managed_virtual_network_enabled = var.managed_virtual_network_enabled
  public_network_enabled          = var.public_network_enabled
  purview_id                      = var.purview_id

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
    for_each = var.global_parameters
    content {
      name  = lookup(global_parameter.value, "name", global_parameter.key)
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition = var.identity == null || length(local.identity_type_tokens) > 0
      error_message = "The identity configuration must enable the system-assigned identity, attach user-assigned identities, or specify a valid identity type."
    }

    precondition {
      condition = local.identity_config == null || length(local.identity_user_assigned_identity_ids) == 0 || local.use_user_assigned_identity
      error_message = "User-assigned identity IDs were provided but the identity type does not include UserAssigned."
    }

    precondition {
      condition = !local.use_user_assigned_identity || length(local.identity_user_assigned_identity_ids) > 0
      error_message = "At least one user-assigned identity ID must be provided when the identity type includes UserAssigned."
    }

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

    precondition {
      condition = var.customer_managed_key_identity_id == null || local.use_user_assigned_identity
      error_message = "customer_managed_key_identity_id was provided but no user-assigned identity is enabled."
    }

    precondition {
      condition = local.identity_config == null || local.identity_config.cmk_user_assigned_identity_id == null || local.use_user_assigned_identity
      error_message = "identity.customer_managed_key_identity_id requires a user-assigned identity."
    }

    precondition {
      condition = !local.use_customer_managed_key || local.customer_managed_key_identity_type != "UserAssigned" || local.customer_managed_key_identity_id != null
      error_message = "A user-assigned identity ID must be supplied for customer managed keys when identity type is UserAssigned."
    }
  }
}
