variable "data_factory_id" {
  description = "The ID of the Data Factory where integration runtimes will be created."
  type        = string
}

variable "integration_runtimes" {
  description = <<-DESC
  Map describing the integration runtimes to manage. The map key defaults to the runtime name when `name` is omitted.
  Supported `type` values are `azure` and `self_hosted`.
  DESC
  type = map(object({
    type        = string
    name        = optional(string)
    description = optional(string)
    location    = optional(string)

    # Azure integration runtime settings
    compute_type            = optional(string)
    core_count              = optional(number)
    time_to_live            = optional(number)
    virtual_network_enabled = optional(bool)

    # Self-hosted integration runtime settings
    rbac_authorization = optional(object({
      resource_id  = string
      principal_id = string
      tenant_id    = string
    }))
  }))

  validation {
    condition = alltrue([
      for runtime in values(var.integration_runtimes) :
      contains(["azure", "self_hosted"], lower(runtime.type))
    ])

    error_message = "Each integration runtime entry must set type to either azure or self_hosted."
  }
}

variable "default_azure_location" {
  description = "Fallback location to use for Azure integration runtimes when a location is not explicitly provided per runtime."
  type        = string
  default     = null
}
