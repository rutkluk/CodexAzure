
variable "factory_name" {
  description = "Nazwa instancji Azure Data Factory."
  type        = string
}

variable "resource_group_name" {
  description = "Grupa zasobów docelowa."
  type        = string
}

variable "location" {
  description = "Region Azure."
  type        = string
}

variable "managed_virtual_network_enabled" {
  description = "Włącza Managed Virtual Network dla ADF (Azure IR w MvNet)."
  type        = bool
  default     = true
}

variable "public_network_enabled" {
  description = "Włącza publiczny dostęp do control‑plane ADF."
  type        = bool
  default     = false
}

variable "enable_control_plane_private_endpoint" {
  description = "Tworzy Private Endpointy (dataFactory, portal) dla control‑plane ADF, gdy public_network_enabled=false."
  type        = bool
  default     = true
}

variable "identity" {
  description = "Opcjonalna konfiguracja tożsamości zarządzanej."
  type = object({
    type                             = optional(string)
    enable_system_assigned_identity  = optional(bool)
    user_assigned_identity_ids       = optional(list(string), [])
    customer_managed_key_identity_id = optional(string)
  })
  default = null
}

variable "environment" {
  description = "Środowisko wdrożenia (dev|test|pre|prod)."
  type        = string
  default     = "dev"
}

variable "customer_managed_key_id" {
  description = "ID klucza Key Vault dla CMK (może być wersjonowane — moduł normalizuje)."
  type        = string
  default     = null
}

variable "customer_managed_key_identity_id" {
  description = "UAMI używana do autoryzacji CMK (opcjonalnie)."
  type        = string
  default     = null
}

variable "github_configuration" {
  description = "Opcjonalna integracja GitHub."
  type = object({
    account_name    = string
    branch_name     = string
    git_url         = string
    repository_name = string
    root_folder     = optional(string)
  })
  default = null
}

variable "purview_id" {
  description = "Opcjonalny ID Purview do powiązania."
  type        = string
  default     = null
}

variable "global_parameters" {
  description = "Global parameters ADF."
  type = map(object({
    type  = string
    value = string
    name  = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tagi zasobu."
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "ID Key Vault (dla CMK oraz Linked Service / MPE)."
  type        = string
  default     = null
}

variable "subnet" {
  description = "Podsieć podstawowa (dla przykładowych zasobów)."
  type = object({
    resource_group_name = string
    vnet_name           = string
    cidr                = string
  })
}

variable "subnet_pe" {
  description = "Podsieć dla Private Endpointów control‑plane."
  type = object({
    resource_group_name = string
    vnet_name           = string
    cidr                = string
  })
}

variable "enable_kv_managed_private_endpoint" {
  description = "Tworzy Managed Private Endpoint z ADF (Managed VNet) do Key Vault (data plane)."
  type        = bool
  default     = true
}

variable "create_key_vault_linked_service" {
  description = "Tworzy Linked Service do Key Vault w ADF."
  type        = bool
  default     = true
}
