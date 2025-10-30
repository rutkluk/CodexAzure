variable "data_factory_id" {
  description = "The ID of the Data Factory where managed private endpoints will be created."
  type        = string
}

variable "endpoints" {
  description = "Map of managed private endpoints to create. Key defaults to name."
  type = map(object({
    name               = optional(string)
    target_resource_id = string
    subresource_name   = string # e.g., "vault", "blob", "dfs", "sqlServer"
    description        = optional(string)
  }))
}

