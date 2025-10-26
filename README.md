# CodexAzure

This repository contains reusable Terraform components for Azure resources. The initial release introduces a module for deploying Azure Data Factory (V2) instances with the `azurerm` provider pinned to version `4.37.0`. It also includes companion modules for managing custom linked services inside an existing factory, provisioning integration runtimes, configuring pipeline triggers, and creating user-assigned managed identities with role assignments.

## Modules

### `data_factory_v2`

Creates an Azure Data Factory V2 instance with optional Managed Identity and GitHub repository integration.

#### Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `factory_name` | `string` | n/a | The name of the Azure Data Factory instance. |
| `resource_group_name` | `string` | n/a | The resource group in which to create the Data Factory. |
| `location` | `string` | n/a | The Azure region for the Data Factory. |
| `managed_virtual_network_enabled` | `bool` | `true` | Enables Managed Virtual Network integration. |
| `public_network_enabled` | `bool` | `true` | Enables public network access. |
| `identity` | `object` | `null` | Optional managed identity configuration controlling system-assigned and/or user-assigned identities. |
| `environment` | `string` | `"dev"` | Deployment environment driving conditional behaviors (supports `dev`, `test`, `pre`, `prod`). |
| `customer_managed_key_id` | `string` | `null` | Optional **versionless** customer managed key ID automatically required when `environment` is `pre` or `prod`. |
| `customer_managed_key_identity_id` | `string` | `null` | Optional override specifying the user-assigned identity ID that should authenticate against the customer managed key. |
| `github_configuration` | `object` | `null` | Optional GitHub configuration for source control integration. |
| `purview_id` | `string` | `null` | Optional Azure Purview resource ID to associate with the factory. |
| `global_parameters` | `map(object)` | `{}` | Optional map configuring Data Factory [global parameters](https://learn.microsoft.com/azure/data-factory/iterative-development-debugging#set-global-parameters). |
| `tags` | `map(string)` | `{}` | Optional tags for the Data Factory. |

When providing an `identity` value, configure one or more of the following properties:

- `type` – optional explicit identity type string (for example `SystemAssigned`, `UserAssigned`, or `SystemAssigned, UserAssigned`).
- `enable_system_assigned_identity` – set to `true` to enable the system-assigned identity when `type` is omitted.
- `user_assigned_identity_ids` – provide one or more resource IDs for user-assigned managed identities to attach.
- `customer_managed_key_identity_id` – optional user-assigned identity ID to use with the customer managed key when no module-level override is supplied.

The module dynamically derives (or normalizes) the identity `type` for the Data Factory resource from these inputs, allowing the following combinations:

1. Only system-assigned (for example `type = "SystemAssigned"` or `enable_system_assigned_identity = true`).
2. Only user-assigned (for example `type = "UserAssigned"` or providing `user_assigned_identity_ids`).
3. Both system- and user-assigned identities (`type = "SystemAssigned, UserAssigned"` or combining `enable_system_assigned_identity = true` with a non-empty `user_assigned_identity_ids`). When a customer managed key is configured, the module prefers the user-assigned identity for encryption; if none is available, it falls back to the system-assigned identity.

For environments marked as `pre` or `prod`, supply `customer_managed_key_id` with the versionless Azure Key Vault key ID (for example, using `azurerm_key_vault_key.example.versionless_id`) that should encrypt the factory. The module normalizes versioned inputs to avoid unwanted key regeneration, enforces this requirement with a Terraform precondition, and will also apply the key to other environments whenever a value is provided.

When a customer managed key is enabled, the module ensures that a compatible managed identity is configured, prefers a user-assigned identity for encryption when available (hard default), and allows explicitly overriding the identity used via either `customer_managed_key_identity_id` or the nested identity configuration.

##### CMK Identity and Key Vault Permissions

- CMK enabled requires a managed identity. This module prefers a user-assigned identity (UAMI) when present; otherwise it uses the system-assigned identity.
- The selected identity must have appropriate Key Vault permissions on the key:
  - With RBAC: assign roles such as "Key Vault Crypto User" at the Key Vault scope.
  - With access policies: ensure get, wrapKey, unwrapKey (and decrypt if needed).

You can provision a UAMI and grant roles using the `user_assigned_identity` module, then pass its ID via `identity.user_assigned_identity_ids` and, if needed, `customer_managed_key_identity_id`.

Global parameters can be supplied through `global_parameters`, using objects that specify the `type`, `value`, and optional friendly `name` (defaults to the map key). The module also accepts an optional `purview_id` to integrate the factory with Azure Purview.

#### Outputs

| Name | Description |
|------|-------------|
| `data_factory_id` | The ID of the created Data Factory. |
| `data_factory_name` | The name of the created Data Factory. |
| `managed_virtual_network_enabled` | Indicates whether Managed Virtual Network is enabled. |
| `public_network_enabled` | Indicates whether public network access is enabled. |
| `identity_type` | The effective managed identity type configured on the Data Factory. |
| `identity_principal_id` | The principal ID for the system-assigned identity, when configured. |
| `identity_tenant_id` | The tenant ID for the Data Factory's managed identity. |
| `identity_user_assigned_ids` | The list of user-assigned identity IDs attached to the Data Factory. |

### `data_factory_custom_linked_services`

Creates custom linked services within an existing Azure Data Factory instance.

#### Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `data_factory_id` | `string` | n/a | The ID of the Data Factory that will host the linked services. |
| `linked_services` | `map(object)` | n/a | Map of linked service definitions keyed by name. Each object supports `type`, `type_properties_json`, and optional `name`, `annotations`, `additional_properties`, `parameters`, and `integration_runtime_name`. |

Each entry inherits sensible defaults: when `name` is omitted the map key is used, and unspecified optional collections resolve to `null` so Terraform omits them from the resulting resource.

#### Outputs

| Name | Description |
|------|-------------|
| `linked_service_ids` | Map of linked service names to their IDs. |
| `linked_service_names` | List of linked service names managed by this module. |

The [`examples/dataverse_custom_linked_service`](examples/dataverse_custom_linked_service/main.tf) scenario shows how to define a Dataverse linked service that authenticates with a service principal whose secret is stored in Azure Key Vault. Additional standalone samples demonstrate other authentication models:

- [`examples/mssql_custom_linked_service`](examples/mssql_custom_linked_service/main.tf) – configures an Azure SQL Database linked service that reads both the SQL authentication username and password from Key Vault secrets.
- [`examples/azure_storage_uami_linked_service`](examples/azure_storage_uami_linked_service/main.tf) – configures an Azure Blob Storage linked service that authenticates with a user-assigned managed identity.

### `data_factory_integration_runtimes`

Creates Azure and self-hosted integration runtimes for an existing Azure Data Factory instance.

#### Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `data_factory_id` | `string` | n/a | The ID of the Data Factory that will host the integration runtimes. |
| `integration_runtimes` | `map(object)` | n/a | Map describing each runtime. Entries require a `type` (`azure` or `self_hosted`) and optional runtime-specific settings such as `description`, `location`, compute sizing, and RBAC authorization. |

Runtime names automatically default to the map key when `name` is not provided, and the module normalizes the declared `type` to the casing expected by the AzureRM provider.
| `default_azure_location` | `string` | `null` | Optional fallback location for Azure integration runtimes when one is not specified per entry. |

#### Outputs

| Name | Description |
|------|-------------|
| `integration_runtime_ids` | Map of integration runtime keys to their resource IDs. |
| `integration_runtime_names` | List of integration runtime names managed by this module. |

### `data_factory_pipeline_triggers`

Creates schedule- and tumbling-window-based triggers for Azure Data Factory pipelines.

#### Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `data_factory_id` | `string` | n/a | The ID of the Data Factory where triggers will be created. |
| `triggers` | `map(object)` | n/a | Map describing each trigger. Supported `type` values are `schedule` and `tumbling_window`. |

Trigger names default to their map key when `name` is not explicitly set, and triggers are activated by default unless overridden via the optional `activated` flag.

When defining `triggers`:

- Schedule triggers require a nested `schedule` object mirroring the attributes of the Terraform `schedule` block (for example `frequency`, `interval`, `start_time`, `time_zone`, and recurrence settings).
- Tumbling window triggers require `frequency`, `interval`, and `start_time`. Optional fields such as `delay`, `end_time`, `max_concurrency`, and a `retry` block are supported.

#### Outputs

| Name | Description |
|------|-------------|
| `trigger_ids` | Map of trigger keys to their resource IDs. |
| `trigger_names` | Map of trigger keys to the created trigger names. |

### `user_assigned_identity`

Creates a user-assigned managed identity and (optionally) assigns roles at one or more scopes.

Inputs
- `name` (string)
- `resource_group_name` (string)
- `location` (string)
- `tags` (map(string), default `{}`)
- `role_assignments` (list) — each item has:
  - `scope` (string Azure resource ID)
  - one of `role_definition_id` or `role_definition_name`
  - optional `condition`, `condition_version`

Outputs
- `id`, `principal_id`, `client_id`, `name`

Example
```
module "uami" {
  source = "./modules/user_assigned_identity"

  name                = "uami-adf"
  resource_group_name = "rg-demo"
  location            = "westeurope"

  role_assignments = [
    {
      scope                = "/subscriptions/000.../resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
      role_definition_name = "Key Vault Crypto User"
    }
  ]
}

module "data_factory" {
  source = "./modules/data_factory_v2"
  # ...
  identity = {
    type                       = "UserAssigned"
    user_assigned_identity_ids = [module.uami.id]
  }
  customer_managed_key_id = "/subscriptions/000.../providers/Microsoft.KeyVault/vaults/kv-demo/keys/adf-key"
}
```

## Examples

Dedicated examples demonstrate how to configure the Data Factory module with each managed identity combination:

- [`examples/user_assigned_identity`](examples/user_assigned_identity/main.tf) – attaches only a user-assigned managed identity.
- [`examples/system_identity`](examples/system_identity/main.tf) – enables only the system-assigned identity.
- [`examples/system_and_user_identities`](examples/system_and_user_identities/main.tf) – combines system- and user-assigned identities and illustrates customer-managed key usage in a production environment.
- [`examples/dataverse_custom_linked_service`](examples/dataverse_custom_linked_service/main.tf) – configures a Dataverse linked service using service principal authentication.
- [`examples/mssql_custom_linked_service`](examples/mssql_custom_linked_service/main.tf) – configures a SQL Database linked service using Key Vault-stored SQL authentication credentials.
- [`examples/azure_storage_uami_linked_service`](examples/azure_storage_uami_linked_service/main.tf) - configures a Blob Storage linked service secured by a user-assigned managed identity.

The [`examples/simple`](examples/simple/main.tf) scenario showcases a combined deployment using all submodules:
- Creates a user-assigned managed identity with sample RBAC.
- Deploys the Data Factory (with networking, Purview, and CMK wiring that prefers UAMI).
- Creates an ADF Credential for the UAMI.
- Provisions Azure and self-hosted integration runtimes.
- Adds a sample custom linked service.
- Configures schedule and tumbling window triggers.

### `data_factory_credentials`

Creates Data Factory Credentials. Currently supports the User Assigned Managed Identity (UAMI) credential type.

Inputs
- `data_factory_id` (string) — target Data Factory ID
- `credentials_uami` (map) — each value supports:
  - `name` (optional string; defaults to map key)
  - `identity_id` (string; UAMI resource ID)
  - `annotations` (optional list(string))

Outputs
- `credential_ids` — map of keys to credential IDs
- `credential_names` — map of keys to names

Example
```
module "uami" {
  source = "./modules/user_assigned_identity"
  name                = "uami-adf"
  resource_group_name = "rg-demo"
  location            = "westeurope"
}

module "data_factory" {
  source = "./modules/data_factory_v2"
  # ... required inputs ...
  identity = {
    type                       = "UserAssigned"
    user_assigned_identity_ids = [module.uami.id]
  }
}

module "adf_credentials" {
  source = "./modules/data_factory_v2/data_factory_credentials"

  data_factory_id = module.data_factory.data_factory_id

  credentials_uami = {
    uamiDefault = {
      identity_id = module.uami.id
      annotations = ["primary-uami"]
    }
  }
}
```
