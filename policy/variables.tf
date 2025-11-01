########################################
# General Settings
########################################

variable "policy_initiative_name" {
  description = "The name of the Azure Policy Initiative (policy set definition) for secure ADF configuration."
  type        = string
  default     = "Secure-ADF-Baseline"
}

variable "policy_assignment_name" {
  description = "The name of the Azure Policy Assignment for enforcing the secure ADF baseline."
  type        = string
  default     = "enforce-secure-adf"
}

variable "policy_category" {
  description = "Category under which the ADF policies will appear in Azure Policy."
  type        = string
  default     = "Data Factory"
}

variable "policy_version" {
  description = "Version label for the ADF policy initiative."
  type        = string
  default     = "1.0.0"
}

########################################
# Subscription / Scope
########################################

variable "subscription_id" {
  description = "The target Azure Subscription ID where the policy initiative will be assigned."
  type        = string
  default     = ""
}

########################################
# Region Restrictions
########################################

variable "allowed_regions" {
  description = "List of Azure regions where Azure Data Factory is allowed to be deployed."
  type        = list(string)
  default = [
    "westeurope",
    "northeurope"
  ]
}

########################################
# Enforcement Control
########################################

variable "enforcement_mode" {
  description = <<EOT
Enforcement mode for the policy assignment.
Use 'Default' to enforce (deny noncompliant resources),
or 'DoNotEnforce' for audit-only mode.
EOT
  type        = string
  default     = "Default"
}
