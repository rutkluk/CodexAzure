locals {
  normalized_triggers = {
    for key, value in var.triggers :
    key => merge(value, {
      type                  = lower(value.type)
      name                  = coalesce(try(value.name, null), key)
      activated             = try(value.activated, true)
      pipeline_parameters   = try(value.pipeline_parameters, null)
      annotations           = try(value.annotations, null)
      description           = try(value.description, null)
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

  trigger_ids_schedule = {}
  trigger_ids_tumbling = {}

  trigger_names_schedule = { for key, trigger in local.schedule_triggers : key => trigger.name }
  trigger_names_tumbling = { for key, trigger in local.tumbling_window_triggers : key => trigger.name }
}
