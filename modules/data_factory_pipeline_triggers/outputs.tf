locals {
  schedule_trigger_ids = { for key, trigger in azurerm_data_factory_trigger_schedule.this : key => trigger.id }
  tumbling_trigger_ids = { for key, trigger in azurerm_data_factory_trigger_tumbling_window.this : key => trigger.id }

  schedule_trigger_names = { for key, trigger in azurerm_data_factory_trigger_schedule.this : key => trigger.name }
  tumbling_trigger_names = { for key, trigger in azurerm_data_factory_trigger_tumbling_window.this : key => trigger.name }
}

output "trigger_ids" {
  description = "Map of trigger keys to their resource IDs."
  value       = merge(local.schedule_trigger_ids, local.tumbling_trigger_ids)
}

output "trigger_names" {
  description = "Map of trigger keys to their trigger names."
  value       = merge(local.schedule_trigger_names, local.tumbling_trigger_names)
}
