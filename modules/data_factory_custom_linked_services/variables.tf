variable "data_factory_id" {
  description = "The ID of the Data Factory where linked services will be created."
  type        = string
}

variable "linked_services" {
  description = <<-DESC
  Map of custom linked services to create. The map key defaults to the linked service name when `name` is not explicitly provided.
  DESC
  type = map(object({
    type                     = string
    type_properties_json     = string
    name                     = optional(string)
    annotations              = optional(list(string))
    additional_properties    = optional(map(string))
    parameters               = optional(map(string))
    integration_runtime_name = optional(string)
  }))
}
