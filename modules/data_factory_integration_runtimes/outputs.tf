output "integration_runtime_ids" {
  description = "Map of integration runtime keys to their resource IDs."
  value       = merge(local.integration_runtime_ids_azure, local.integration_runtime_ids_self_hosted)
}

output "integration_runtime_names" {
  description = "List of integration runtime names managed by this module."
  value       = local.integration_runtime_names_all
}
