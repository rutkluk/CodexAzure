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
    type                       = string
    user_assigned_identity_ids = optional(list(string))
  })
  default = null

  validation {
    condition     = var.identity == null ? true : length(regexall("^(SystemAssigned|UserAssigned|SystemAssigned, UserAssigned)$", var.identity.type)) == 1
    error_message = "Identity type must be one of 'SystemAssigned', 'UserAssigned', or 'SystemAssigned, UserAssigned'."
  }

  validation {
    condition = var.identity == null ? true : (
      length(regexall("UserAssigned", var.identity.type)) == 0 || length(coalesce(var.identity.user_assigned_identity_ids, [])) > 0
    )
    error_message = "At least one user_assigned_identity_ids value must be provided when using a UserAssigned identity."
  }
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
