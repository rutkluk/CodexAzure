variable "factory_name" {
  description = "The name of the Azure Data Factory instance."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the Data Factory will be deployed."
  type        = string
}

variable "location" {
  description = "Azure region where the Data Factory will be created."
  type        = string
}

variable "managed_virtual_network_enabled" {
  description = "Flag to enable Managed Virtual Network for the Data Factory."
  type        = bool
  default     = true
}

variable "public_network_enabled" {
  description = "Flag to enable public network access for the Data Factory."
  type        = bool
  default     = true
}

variable "identity" {
  description = "Optional managed identity configuration for the Data Factory."
  type = object({
    type         = string
    principal_id = optional(string)
    tenant_id    = optional(string)
  })
  default = null
}

variable "github_configuration" {
  description = "Optional GitHub configuration for integration with Data Factory."
  type = object({
    account_name    = string
    branch_name     = string
    git_url         = string
    repository_name = string
    root_folder     = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Optional tags to assign to the Data Factory."
  type        = map(string)
  default     = {}
}
