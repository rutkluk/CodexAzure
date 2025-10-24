# CodexAzure

This repository contains reusable Terraform components for Azure resources. The initial release introduces a module for deploying Azure Data Factory (V2) instances with the `azurerm` provider pinned to version `4.37.0`. It also includes a companion module for managing custom linked services inside an existing factory.

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
| `identity` | `object` | `null` | Optional managed identity configuration. |
| `github_configuration` | `object` | `null` | Optional GitHub configuration for source control integration. |
| `tags` | `map(string)` | `{}` | Optional tags for the Data Factory. |

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

#### Outputs

| Name | Description |
|------|-------------|
| `linked_service_ids` | Map of linked service names to their IDs. |
| `linked_service_names` | List of linked service names managed by this module. |

## Example

An example configuration can be found under [`examples/simple`](examples/simple/main.tf):

```hcl
module "data_factory" {
  source = "../../modules/data_factory_v2"

  factory_name        = "df-demo-001"
  resource_group_name = "rg-demo"
  location            = "westeurope"

  tags = {
    environment = "demo"
    component   = "data-factory"
  }
}

module "custom_linked_services" {
  source = "../../modules/data_factory_custom_linked_services"

  data_factory_id = module.data_factory.data_factory_id

  linked_services = {
    "demoBlob" = {
      type = "AzureBlobStorage"
      type_properties_json = jsonencode({
        connectionString = "DefaultEndpointsProtocol=https;AccountName=example;AccountKey=example;EndpointSuffix=core.windows.net"
      })
      annotations = ["example"]
    }
  }
}
```
