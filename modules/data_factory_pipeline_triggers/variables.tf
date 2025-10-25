variable "data_factory_id" {
  type        = string
  description = "The ID of the Data Factory that will host the triggers."
}

variable "triggers" {
  type = map(object({
    type                 = string
    name                 = optional(string)
    pipeline_name        = string
    annotations          = optional(list(string))
    description          = optional(string)
    activated            = optional(bool)
    pipeline_parameters  = optional(map(any))
    additional_properties = optional(map(string))
    schedule             = optional(any)
    frequency            = optional(string)
    interval             = optional(number)
    start_time           = optional(string)
    end_time             = optional(string)
    delay                = optional(string)
    max_concurrency      = optional(number)
    retry                = optional(object({
      count               = optional(number)
      interval_in_seconds = optional(number)
    }))
  }))
  description = <<EOT
Map describing pipeline triggers to create. Supported types:
- `schedule`: requires a nested `schedule` object mirroring the azurerm_data_factory_trigger_schedule schedule block.
- `tumbling_window`: requires `frequency`, `interval`, and `start_time` properties.
EOT

  validation {
    condition = alltrue([
      for trigger in values(var.triggers) : contains(["schedule", "tumbling_window"], lower(trigger.type))
    ])
    error_message = "Each trigger must specify a supported type (schedule or tumbling_window)."
  }
}
