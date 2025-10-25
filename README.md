# CodexAzure

This repository contains reusable Terraform components for Azure resources. The initial release introduces a module for deploying Azure Data Factory (V2) instances with the `azurerm` provider pinned to version `4.37.0`. It also includes companion modules for managing custom linked services inside an existing factory, provisioning integration runtimes, and configuring pipeline triggers.

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
| `github_configuration` | `object` | `null` | Optional GitHub configuration for source control integration. |
| `tags` | `map(string)` | `{}` | Optional tags for the Data Factory. |

When providing an `identity` value, configure one or both of the following properties:

- `enable_system_assigned_identity` – set to `true` to enable the system-assigned identity.
- `user_assigned_identity_ids` – provide one or more resource IDs for user-assigned managed identities to attach.

The module dynamically derives the identity `type` for the Data Factory resource from these inputs, allowing the following combinations:

1. Only system-assigned (`enable_system_assigned_identity = true`).
2. Only user-assigned (`user_assigned_identity_ids` contains at least one value).
3. Both system- and user-assigned identities (`enable_system_assigned_identity = true` and a non-empty `user_assigned_identity_ids`). In this case, the customer managed key (if configured) is associated with the system-assigned identity.

For environments marked as `pre` or `prod`, supply `customer_managed_key_id` with the versionless Azure Key Vault key ID (for example, using `azurerm_key_vault_key.example.versionless_id`) that should encrypt the factory. The module normalizes versioned inputs to avoid unwanted key regeneration, enforces this requirement with a Terraform precondition, and will also apply the key to other environments whenever a value is provided.

When a customer managed key is enabled, the module ensures that a compatible managed identity is configured and automatically maps the key to the system-assigned identity when both identity types are in use.

#### Outputs

| Name | Description |
|------|-------------|
| `data_factory_id` | The ID of the created Data Factory. |
| `data_factory_name` | The name of the created Data Factory. |
| `managed_virtual_network_enabled` | Indicates whether Managed Virtual Network is enabled. |
| `public_network_enabled` | Indicates whether public network access is enabled. |

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

The [`examples/dataverse_custom_linked_service`](examples/dataverse_custom_linked_service/main.tf) scenario shows how to define a
Dataverse linked service that authenticates with a service principal whose secret is stored in Azure Key Vault.

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

## Examples

Dedicated examples demonstrate how to configure the Data Factory module with each managed identity combination:

- [`examples/user_assigned_identity`](examples/user_assigned_identity/main.tf) – attaches only a user-assigned managed identity.
- [`examples/system_identity`](examples/system_identity/main.tf) – enables only the system-assigned identity.
- [`examples/system_and_user_identities`](examples/system_and_user_identities/main.tf) – combines system- and user-assigned identities and illustrates customer-managed key usage in a production environment.
- [`examples/dataverse_custom_linked_service`](examples/dataverse_custom_linked_service/main.tf) – configures a Dataverse linked service using service principal authentication.

The [`examples/simple`](examples/simple/main.tf) scenario continues to showcase composing the Data Factory deployment with custom linked services.
It now also provisions Azure and self-hosted integration runtimes using the dedicated module and creates both schedule and tumbling window triggers for sample pipelines.
