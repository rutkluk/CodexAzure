output "metric_alert_ids" {
  description = "Map of alert keys to created Metric Alert resource IDs."
  value       = { for k, v in azurerm_monitor_metric_alert.this : k => v.id }
}

output "diagnostic_setting_id" {
  description = "ID of the diagnostic setting (if created)."
  value       = try(azurerm_monitor_diagnostic_setting.this[0].id, null)
}

