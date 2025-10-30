variable "data_factory_id" {
  description = "The ID of the target Azure Data Factory."
  type        = string
}

variable "credentials_uami" {
  description = "Map of user-assigned managed identity credentials to create. Keys are used as default names."
  type = map(object({
    name        = optional(string)
    identity_id = string
    annotations = optional(list(string))
  }))
  default = {}
}

