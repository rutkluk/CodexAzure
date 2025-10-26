output "trigger_ids" {
  description = "Map of trigger keys to their resource IDs."
  value       = merge(local.trigger_ids_schedule, local.trigger_ids_tumbling)
}

output "trigger_names" {
  description = "Map of trigger keys to their trigger names."
  value       = merge(local.trigger_names_schedule, local.trigger_names_tumbling)
}

