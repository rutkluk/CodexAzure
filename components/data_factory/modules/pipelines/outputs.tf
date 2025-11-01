output "pipeline_ids" {
  description = "Mapowanie klucza do ID utworzonych pipeline."
  value       = { for k, v in azurerm_data_factory_pipeline.this : k => v.id }
}

output "pipeline_names" {
  description = "Mapowanie klucza do nazw pipeline."
  value       = { for k, v in azurerm_data_factory_pipeline.this : k => v.name }
}

