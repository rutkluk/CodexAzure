########################################
# Outputs for Secure ADF Baseline Policy
########################################

output "policy_set_definition_id" {
  description = "The full resource ID of the Secure Azure Data Factory Baseline policy set definition."
  value       = azurerm_policy_set_definition.secure_adf_baseline.id
}

output "policy_set_definition_name" {
  description = "The name of the Secure Azure Data Factory Baseline policy set definition."
  value       = azurerm_policy_set_definition.secure_adf_baseline.name
}

output "policy_assignment_id" {
  description = "The full resource ID of the policy assignment enforcing the secure ADF baseline."
  value       = azurerm_policy_assignment.secure_adf_assignment.id
}

output "policy_assignment_name" {
  description = "The name of the policy assignment enforcing the secure ADF baseline."
  value       = azurerm_policy_assignment.secure_adf_assignment.name
}

output "policy_assignment_scope" {
  description = "The scope (subscription or resource group) where the secure ADF policy baseline is assigned."
  value       = azurerm_policy_assignment.secure_adf_assignment.scope
}

output "allowed_regions" {
  description = "List of allowed Azure regions for ADF deployments as enforced by the policy."
  value       = var.allowed_regions
}
