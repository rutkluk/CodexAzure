# CodexAzure

To repozytorium zawiera wielokrotnego użytku komponenty Terraform dla zasobów Azure, w szczególności komplet modułów do wdrażania i zabezpieczania Azure Data Factory (ADF) z providerem `azurerm` w wersji `=4.37.0`.

Domyślne założenia bezpieczeństwa (komponent `components/data_factory/default`):
- `managed_virtual_network_enabled = true` — Azure IR działa w zarządzanej sieci ADF (Managed VNet).
- `public_network_enabled = false` — dostęp do control‑plane (Studio/API) nie jest publiczny.
- `enable_control_plane_private_endpoint = true` — tworzymy Private Endpointy do Studio/API (subresource: `dataFactory` i `portal`) oraz powiązane prywatne strefy DNS.

Gdy ustawisz `public_network_enabled = true`:
- komponent nie utworzy Private Endpointów control‑plane (warunkowe `count/for_each`),
- oraz obowiązuje precondition: nie można jednocześnie mieć `public_network_enabled = true` i `enable_control_plane_private_endpoint = true`.

Dostęp do źródeł danych w trybie prywatnym realizuj przez:
- Managed Private Endpoints w Managed VNet ADF (dla Azure IR), lub
- Self‑Hosted IR w Twojej sieci/VNet.
Private Endpoint control‑plane dotyczy tylko portalu/API (Studio), a nie przepływu danych.

## Komponenty i moduły

### Komponent ADF: `components/data_factory/default`
Tworzy ADF (V2) z opcjonalnymi tożsamościami (systemową i/lub UAMI), integracją z GitHub, CMK, a także (warunkowo) Private Endpointami control‑plane i prywatnym DNS.

Najważniejsze wejścia
- `factory_name` (string) — nazwa ADF
- `resource_group_name` (string) — grupa zasobów
- `location` (string) — region Azure
- `managed_virtual_network_enabled` (bool, domyślnie true) — Managed VNet ADF
- `public_network_enabled` (bool, domyślnie false) — publiczny dostęp do control‑plane
- `enable_control_plane_private_endpoint` (bool, domyślnie true) — PE dla Studio/API (gdy `public_network_enabled = false`)
- `identity` (object, opcjonalnie) — konfiguracja tożsamości (typ, lista UAMI, itp.)
- `environment` (string, domyślnie `dev`) — środowisko (`dev|test|pre|prod`)
- `customer_managed_key_id` (string, opcjonalnie) — ID klucza Key Vault (moduł normalizuje do „versionless”)
- `customer_managed_key_identity_id` (string, opcjonalnie) — UAMI do autoryzacji CMK
- `github_configuration` (object, opcjonalnie) — integracja repozytorium
- `purview_id` (string, opcjonalnie) — integracja z Purview
- `global_parameters` (map(object), domyślnie `{}`)
- `tags` (map(string), domyślnie `{}`)
- `key_vault_id` (string, opcjonalnie) — Key Vault dla CMK (np. w `pre/prod`)
- `subnet`, `subnet_pe` (object) — podsieci tworzone lokalnie (np. dla PE control‑plane)

Zachowanie CMK i tożsamości
- Moduł preferuje tożsamość UAMI do CMK, jeśli jest dostępna; w przeciwnym razie użyje systemowej.
- W `pre/prod` wymagane jest `customer_managed_key_id` (precondition).
- Precondition pilnują spójności kombinacji tożsamości i CMK.

Control‑plane Private Endpointy i DNS
- Tworzone tylko, gdy `enable_control_plane_private_endpoint = true` oraz `public_network_enabled = false`.
- Subresource’y: `dataFactory` i `portal` (oddzielne PE przez `for_each`).
- Prywatne strefy DNS (global Azure): `privatelink.datafactory.azure.net` i `privatelink.adf.azure.com`.

Najważniejsze wyjścia
- `data_factory_id`, `data_factory_name`
- `managed_virtual_network_enabled`, `public_network_enabled`
- `identity_type`, `identity_principal_id`, `identity_tenant_id`, `identity_user_assigned_ids`

Tabela wejsc (komponent ADF)
| Nazwa | Typ | Domyslnie | Opis |
|------|-----|-----------|------|
| factory_name | string | — | Nazwa instancji ADF |
| resource_group_name | string | — | Grupa zasobow dla ADF |
| location | string | — | Region Azure |
| managed_virtual_network_enabled | bool | true | Wlaczenie Managed VNet dla Azure IR |
| public_network_enabled | bool | false | Dostep publiczny do control‑plane |
| enable_control_plane_private_endpoint | bool | true | Tworzenie PE dla `dataFactory` i `portal` (gdy public_network_enabled=false) |
| identity | object | null | Konfiguracja tozsamosci (SystemAssigned/UserAssigned) |
| environment | string | "dev" | Srodowisko: dev/test/pre/prod |
| customer_managed_key_id | string | null | ID klucza KV (wejscie moze byc wersjonowane; modul normalizuje) |
| customer_managed_key_identity_id | string | null | UAMI do autoryzacji CMK |
| github_configuration | object | null | Integracja z GitHub (repo/branch/url) |
| purview_id | string | null | ID Purview do powiazania |
| global_parameters | map(object) | {} | Global parameters ADF (typ/wartosc/nazwa) |
| tags | map(string) | {} | Tagi zasobu |
| key_vault_id | string | null | ID Key Vault dla CMK (np. w pre/prod) |
| subnet | object | — | Podsiec podstawowa (rg, vnet, cidr) |
| subnet_pe | object | — | Podsiec dla PE control‑plane (rg, vnet, cidr) |

Tabela wyjsc (komponent ADF)
| Nazwa | Opis |
|------|------|
| data_factory_id | ID utworzonej fabryki danych |
| data_factory_name | Nazwa utworzonej fabryki |
| managed_virtual_network_enabled | Czy wlaczono Managed VNet |
| public_network_enabled | Czy wlaczono dostep publiczny do control‑plane |
| identity_type | Efektywny typ tozsamosci na ADF |
| identity_principal_id | Principal ID tozsamosci systemowej (gdy wlaczona) |
| identity_tenant_id | Tenant ID tozsamosci |
| identity_user_assigned_ids | Lista ID UAMI przypietych do ADF |

### Moduł: `components/data_factory/modules/credentials`
Tworzy poświadczenia (Credentials) w ADF. W `azurerm 4.37.0` obsługuje UAMI.
- Wejścia: `data_factory_id`, `credentials_uami` (mapa definicji)
- Wyjścia: `credential_ids`, `credential_names`

### Moduł: `components/data_factory/modules/custom_linked_services`
Placeholder dla 4.37.0 (brak generycznego zasobu Linked Service).
- Służy jako „pass‑through” do czasu wdrożenia typów specyficznych lub nowszego providera.

### Moduł: `components/data_factory/modules/runtimes`
Azure Integration Runtime i Self‑Hosted IR.
- Zgodny z 4.37.0 (usunięte nieobsługiwane atrybuty typu `time_to_live`).

### Moduł: `components/data_factory/modules/alerts_and_metrics`
Alerty metryczne ADF (`azurerm_monitor_metric_alert`) + diagnostyka (`azurerm_monitor_diagnostic_setting`).
- Obsługa Action Groups, kryteriów metryk i opcjonalnego kierowania logów/metryk do Log Analytics/Storage/Event Hub.

### Moduł: `components/data_factory/modules/private_endpoints`
Managed Private Endpoints z ADF (dla danych) w Managed VNet ADF.
- Subresource: Key Vault `vault`; Storage `blob|dfs|file|table`; Azure SQL `sqlServer`.

### Moduł: `modules/user_assigned_identity`
Tworzy UAMI i przypisuje role (RBAC) na wskazanych zakresach.
- Wejścia: `name`, `resource_group_name`, `location`, `role_assignments[]`, `tags`
- Wyjścia: `id`, `principal_id`, `client_id`, `name`

## Przykłady
- `examples/system_identity` — tylko tożsamość systemowa ADF (`components/data_factory/default`).
- `examples/user_assigned_identity` — UAMI + przypisanie roli, ADF używa UAMI.
- `examples/system_and_user_identities` — kombinacja systemowej i UAMI + CMK.
- `examples/azure_storage_uami_linked_service` — przykład LS (module placeholder).
- `examples/dataverse_custom_linked_service` — LS dla Dataverse.
- `examples/mssql_custom_linked_service` — LS dla Azure SQL z sekretami w KV.
- `examples/alerts_and_metrics` — alerty metryczne i diagnostyka ADF.
- `examples/private_endpoints` — Managed Private Endpoint z ADF do Key Vault.
- `examples/simple` — kompozycja: UAMI + ADF + Credentials + Runtimes + LS.

## Uwaga o wersji providera (4.37.0)
- Brak generycznego zasobu Linked Service — moduł LS jest „pass‑through”. Jeśli potrzebujesz LS od razu, można dodać typy specyficzne (Blob/ADLS/SQL) albo przejść na nowszą wersję providera.
- Schemat triggerów jest inny i bardziej restrykcyjny; w tym repo moduł triggerów został pominięty, aby utrzymać walidację. Chętnie dodamy zgodny moduł po ustaleniu wymagań.

## Szybki start

Wymagania
- Terraform ≥ 1.5
- Provider `hashicorp/azurerm` w wersji `=4.37.0`
- Uprawnienia do subskrypcji (np. przez `az login` lub zmienne środowiskowe)

1) Minimalna fabryka danych (ADF) z ustawieniami domyślnymi
```
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "=4.37.0" }
  }
}

provider "azurerm" { features {} }

module "data_factory" {
  source = "./components/data_factory/default"

  factory_name        = "df-demo"
  resource_group_name = "rg-demo"
  location            = "westeurope"

  # Domyślnie:
  # managed_virtual_network_enabled = true
  # public_network_enabled          = false
  # enable_control_plane_private_endpoint = true

  subnet = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.10.1.0/24"
  }
  subnet_pe = {
    resource_group_name = "rg-demo"
    vnet_name           = "vnet-demo"
    cidr                = "10.10.2.0/24"
  }
}
```

2) (Opcjonalnie) UAMI + podpięcie do ADF
```
module "uami" {
  source              = "./modules/user_assigned_identity"
  name                = "uami-adf"
  resource_group_name = "rg-demo"
  location            = "westeurope"
}

module "data_factory" {
  # ... (jak wyżej)
  identity = {
    type                       = "UserAssigned"
    user_assigned_identity_ids = [module.uami.id]
  }
}
```

3) (Opcjonalnie) Poświadczenia ADF z UAMI
```
module "adf_credentials" {
  source         = "./components/data_factory/modules/credentials"
  data_factory_id = module.data_factory.data_factory_id

  credentials_uami = {
    primary = { identity_id = module.uami.id }
  }
}
```

4) (Opcjonalnie) Managed Private Endpoint do Key Vault (dla Azure IR w Managed VNet)
```
module "adf_private_endpoints" {
  source         = "./components/data_factory/modules/private_endpoints"
  data_factory_id = module.data_factory.data_factory_id

  endpoints = {
    kv = {
      target_resource_id = "/subscriptions/.../resourceGroups/rg-demo/providers/Microsoft.KeyVault/vaults/kv-demo"
      subresource_name   = "vault"
    }
  }
}
```

5) (Opcjonalnie) Alerty metryczne i diagnostyka
```
module "alerts_and_metrics" {
  source              = "./components/data_factory/modules/alerts_and_metrics"
  data_factory_id     = module.data_factory.data_factory_id
  resource_group_name = "rg-demo"

  action_group_ids = ["/subscriptions/.../resourceGroups/rg-demo/providers/microsoft.insights/actionGroups/ag-demo"]

  metric_alerts = {
    failedActivities = {
      metric_name = "FailedActivityRuns"
      aggregation = "Total"
      operator    = "GreaterThan"
      threshold   = 0
      frequency   = "PT5M"
      window_size = "PT5M"
      severity    = 2
    }
  }

  diagnostic = {
    log_analytics_workspace_id = "/subscriptions/.../resourceGroups/rg-demo/providers/Microsoft.OperationalInsights/workspaces/law-demo"
    logs    = [{ category = "PipelineRuns" }, { category = "TriggerRuns" }]
    metrics = [{ category = "AllMetrics", enabled = true }]
  }
}
```

Uruchomienie
- `terraform init`
- `terraform plan`
- `terraform apply`

Sprzątanie
- `terraform destroy`
