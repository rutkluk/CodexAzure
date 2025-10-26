variable "data_factory_id" {
  type        = string
  description = "The ID of the Data Factory that will host the triggers."
}

variable "triggers" {
  type        = any
  description = <<EOT
Map describing pipeline triggers to create. Supported types:
- `schedule`: requires a nested `schedule` object.
- `tumbling_window`: requires `frequency`, `interval`, and `start_time` properties.
EOT

  validation {
    condition = alltrue([
      for trigger in values(var.triggers) : contains(["schedule", "tumbling_window"], lower(trigger.type))
    ])
    error_message = "Each trigger must specify a supported type (schedule or tumbling_window)."
  }
}

