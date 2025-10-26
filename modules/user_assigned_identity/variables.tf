variable "name" {
  description = "Name of the user-assigned managed identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the identity will be created."
  type        = string
}

variable "location" {
  description = "Azure location for the identity."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the identity."
  type        = map(string)
  default     = {}
}

variable "role_assignments" {
  description = "Optional role assignments to grant this identity across scopes."
  type = list(object({
    scope                = string
    role_definition_id   = optional(string)
    role_definition_name = optional(string)
    condition            = optional(string)
    condition_version    = optional(string)
  }))
  default = []
}

