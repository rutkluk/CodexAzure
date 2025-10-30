# data_factory_v2/private_endpoints

Create Azure Data Factory Managed Private Endpoints (MPE) inside the ADF Managed VNet.

- Provider: `azurerm` `=4.37.0`
- Resource: `azurerm_data_factory_managed_private_endpoint`

## Inputs

- `data_factory_id` (string) — Data Factory resource ID.
- `endpoints` (map of objects)
  - `name` (optional string) — defaults to the map key
  - `target_resource_id` (string) — target resource ID (e.g., Key Vault, Storage, SQL)
  - `subresource_name` (string) — Private Link subresource, e.g.:
    - Key Vault: `vault`
    - Storage: `blob`, `dfs`, `file`, `table`
    - Azure SQL: `sqlServer`
  - `description` (optional string) — ignored in azurerm 4.37.0 for this resource

## Outputs

- `managed_private_endpoint_ids` — map of keys to MPE resource IDs
- `managed_private_endpoint_names` — map of keys to MPE names

## Example (Key Vault)

```
module "adf_private_endpoints" {
  source = "../../modules/data_factory_v2/private_endpoints"

  data_factory_id = "/subscriptions/000.../resourceGroups/rg-demo/providers/Microsoft.DataFactory/factories/df-demo"

  endpoints = {
    kv = {
      name               = "mpe-kv-demo"
      target_resource_id = "/subscriptions/000.../resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
      subresource_name   = "vault"
    }
  }
}
```

Notes
- Each MPE requires approval on the target resource.
- DNS inside the ADF Managed VNet is handled by the service; external Private DNS links are not used by MPE.
