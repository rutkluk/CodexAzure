output "linked_service_ids" {
  description = "Map of linked service names to their resource IDs."
  value       = local.linked_service_ids
}

output "linked_service_names" {
  description = "List of linked service names managed by this module."
  value       = local.linked_service_names
}

