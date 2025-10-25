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
    type                             = optional(string)
    enable_system_assigned_identity  = optional(bool)
    user_assigned_identity_ids       = optional(list(string), [])
    customer_managed_key_identity_id = optional(string)
  })
  default = null
}

variable "environment" {
  description = "Deployment environment name used for environment-specific behaviors (e.g., dev, test, pre, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "pre", "prod"], lower(var.environment))
    error_message = "Environment must be one of dev, test, pre, or prod."
  }
}

variable "customer_managed_key_id" {
  description = "The ID of the customer-managed key to associate with the Data Factory when required."
  type        = string
  default     = null
}

variable "customer_managed_key_identity_id" {
  description = "Optional user-assigned managed identity ID that should authenticate to the customer-managed key when required."
  type        = string
  default     = null
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

variable "purview_id" {
  description = "Optional Azure Purview account ID to associate with the Data Factory."
  type        = string
  default     = null
}

variable "global_parameters" {
  description = "Optional map of global parameters to configure on the Data Factory."
  type = map(object({
    type  = string
    value = string
    name  = optional(string)
  }))
  default = {}
}

variable "tags" {
  description = "Optional tags to assign to the Data Factory."
  type        = map(string)
  default     = {}
}
