locals {
  normalized_triggers = {
    for key, value in var.triggers :
    key => merge(value, {
      type                 = lower(value.type)
      name                 = coalesce(try(value.name, null), key)
      activated            = try(value.activated, true)
      pipeline_parameters  = try(value.pipeline_parameters, null)
      annotations          = try(value.annotations, null)
      description          = try(value.description, null)
      additional_properties = try(value.additional_properties, null)
    })
  }

  schedule_triggers = {
    for key, value in local.normalized_triggers :
    key => value if value.type == "schedule"
  }

  tumbling_window_triggers = {
    for key, value in local.normalized_triggers :
    key => value if value.type == "tumbling_window"
  }

  trigger_ids_schedule = { for key, trigger in azurerm_data_factory_trigger_schedule.this : key => trigger.id }
  trigger_ids_tumbling = { for key, trigger in azurerm_data_factory_trigger_tumbling_window.this : key => trigger.id }

  trigger_names_schedule = { for key, trigger in azurerm_data_factory_trigger_schedule.this : key => trigger.name }
  trigger_names_tumbling = { for key, trigger in azurerm_data_factory_trigger_tumbling_window.this : key => trigger.name }
}
