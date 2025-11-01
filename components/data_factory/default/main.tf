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
  name                 = local.subnet_name
  resource_group_name  = var.subnet.resource_group_name
  virtual_network_name = var.subnet.vnet_name
  address_prefixes     = [var.subnet.cidr]
}

resource "azurerm_subnet" "subnet_pe" {
  name                 = local.subnet_pe_name
  resource_group_name  = var.subnet_pe.resource_group_name
  virtual_network_name = var.subnet_pe.vnet_name
  address_prefixes     = [var.subnet_pe.cidr]
}

resource "azurerm_network_security_group" "nsg" {
  name                = local.nsg.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc_pe" {
  subnet_id                 = azurerm_subnet.subnet_pe.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_rule" "default" {
  name                        = "DenyAll"
  protocol                    = "*"
  access                      = "Deny"
  network_security_group_name = azurerm_network_security_group.nsg.name
  direction                   = "Inbound"
  resource_group_name         = var.resource_group_name
  priority                    = 4000
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"

}


resource "azurerm_key_vault_key" "cmk" {
  count        = (var.environment == "prod" || var.environment == "pre") ? 1 : 0
  key_type     = "RSA"
  key_size     = 2048
  key_vault_id = var.key_vault_id
  name         = "cmk"
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
    expire_after         = "P90D"
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

  customer_managed_key_id          = local.use_customer_managed_key ? local.customer_managed_key_versionless_id : null
  customer_managed_key_identity_id = local.customer_managed_key_identity_type == "UserAssigned" ? local.customer_managed_key_identity_id : null

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
      condition     = var.identity == null || length(local.identity_type_tokens) > 0
      error_message = "The identity configuration must enable the system-assigned identity, attach user-assigned identities, or specify a valid identity type."
    }

    precondition {
      condition     = local.identity_config == null || length(local.identity_user_assigned_identity_ids) == 0 || local.use_user_assigned_identity
      error_message = "User-assigned identity IDs were provided but the identity type does not include UserAssigned."
    }

    precondition {
      condition     = !local.use_user_assigned_identity || length(local.identity_user_assigned_identity_ids) > 0
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
      condition     = var.customer_managed_key_identity_id == null || local.use_user_assigned_identity
      error_message = "customer_managed_key_identity_id was provided but no user-assigned identity is enabled."
    }

    precondition {
      condition     = local.identity_config == null || local.identity_config.cmk_user_assigned_identity_id == null || local.use_user_assigned_identity
      error_message = "identity.customer_managed_key_identity_id requires a user-assigned identity."
    }

    precondition {
      condition     = !local.use_customer_managed_key || local.customer_managed_key_identity_type != "UserAssigned" || local.customer_managed_key_identity_id != null
      error_message = "A user-assigned identity ID must be supplied for customer managed keys when identity type is UserAssigned."
    }

    # Public network and Private Endpoint control plane are wzajemnie wykluczające się ustawienia
    precondition {
      condition     = !(var.public_network_enabled && var.enable_control_plane_private_endpoint)
      error_message = "Nie można jednocześnie ustawić public_network_enabled = true oraz enable_control_plane_private_endpoint = true. Przy włączonej sieci publicznej PE control plane nie jest tworzone."
    }
  }
}

resource "azurerm_data_factory_integration_runtime_azure" "default" {
  count                   = var.managed_virtual_network_enabled ? 1 : 0
  name                    = "AutoResolveIntegrationRuntime"
  data_factory_id         = azurerm_data_factory.this.id
  location                = "AutoResolve"
  virtual_network_enabled = true
}

module "dns_zone_datafactory" {
  count         = var.enable_control_plane_private_endpoint && !var.public_network_enabled ? 1 : 0
  source        = "../../../modules/private-dns-zone/default"
  dns_zone_name = "privatelink.datafactory.azure.net"
}

module "dns_zone_portal" {
  count         = var.enable_control_plane_private_endpoint && !var.public_network_enabled ? 1 : 0
  source        = "../../../modules/private-dns-zone/default"
  dns_zone_name = "privatelink.adf.azure.com"
}

// Control Plane (Studio/API)
resource "azurerm_private_endpoint" "pe" {
  for_each                      = (var.enable_control_plane_private_endpoint && !var.public_network_enabled) ? toset(["dataFactory", "portal"]) : toset([])
  name                          = "pec-${each.key}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  subnet_id                     = azurerm_subnet.subnet_pe.id
  custom_network_interface_name = "nic-${each.key}"
  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      each.key == "dataFactory"
      ? module.dns_zone_datafactory[0].private_dns_zone_id
      : module.dns_zone_portal[0].private_dns_zone_id
    ]
  }
  private_service_connection {
    name                           = "psc-${each.key}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_data_factory.this.id
    subresource_names              = [each.key]
  }
}

# MPE from ADF (MVNet) to Key Vault (Data Plane)
module "kv_mpe" {
  source = "../modules/private_endpoints"

  data_factory_id = azurerm_data_factory.this.id

  endpoints = var.enable_kv_managed_private_endpoint && var.managed_virtual_network_enabled && var.key_vault_id != null ? {
    kv = {
      name               = "mpe-kv-(${var.factory_name})"
      target_resource_id = var.key_vault_id
      subresource_name   = "vault"
    }
  } : {}
}

# Default Linked Service to Key Vault
module "kv_ls" {
  source = "../modules/linked_service_key_vault"

  name            = "ls-kv-${var.factory_name}"
  data_factory_id = azurerm_data_factory.this.id
  key_vault_id    = var.key_vault_id
  enabled         = var.create_key_vault_linked_service && var.key_vault_id != null
}

resource "null_resource" "approve_kv_mpe" {
  depends_on = [module.kv_mpe]
  triggers = {
    mpe_ids_json = jsonencode(try(module.kv_mpe.managed_private_endpoint_ids, {}))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      CONNECTION_NAME=$(az keyvault private-endpoint-connection list \
          --vault-name ${local.key_vault_name} \
          --resource-group ${var.resource_group_name} \
          --query "[?properties.privateLinkServiceConnectionState.status!='Approved'].name | [0]" \
          -o tsv
      )

      echo "Pending connection: ${CONNECTION_NAME}"

      if [ -n "${CONNECTION_NAME}" ] && [ "${CONNECTION_NAME}" != "null" ]; then
        az keyvault private-endpoint-connection approve \
          --resource-group ${var.resource_group_name} \
          --vault-name ${local.key_vault_name} \
          --name ${CONNECTION_NAME} \
          --description "Approved automatically by Terraform for ADF Managed Private Endpoint"
      else
        echo "Nie znaleziono zadnego polaczenia w stanie Pending do zatwierdzenia."
      fi
      EOT
  }
}



