terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

############################################################
# Secure Azure Data Factory Baseline
#
# This defines:
# - Custom Policy Initiative (aka Policy Set Definition)
# - Policy Assignment at subscription scope
############################################################

resource "azurerm_policy_set_definition" "secure_adf_baseline" {
  name         = var.policy_initiative_name
  display_name = "Secure Azure Data Factory Baseline"
  policy_type  = "Custom"
  description  = "Ensures Azure Data Factory instances are deployed securely with managed virtual network, public network access disabled, CMK enabled, and restricted regions."

  metadata = jsonencode({
    category = var.policy_category
    version  = var.policy_version
  })

  # NOTE:
  # The policyDefinitionId values below reference built-in policies.
  # Update them if your tenant uses different definition IDs / custom policies.
  #
  # RequireManagedVirtualNetwork
  # DisablePublicNetworkAccess
  # RequireCustomerManagedKey
  # AllowedADFRegions (Allowed locations)
  #
  # Only the AllowedADFRegions element is parameterized at assignment time.

  policy_definitions = [
    {
      policyDefinitionReferenceId = "RequireManagedVirtualNetwork"
      policyDefinitionId          = "/providers/Microsoft.Authorization/policyDefinitions/0f0e3fcb-40e2-4a38-bb70-1b2a6e8cdbeb"
    },
    {
      policyDefinitionReferenceId = "DisablePublicNetworkAccess"
      policyDefinitionId          = "/providers/Microsoft.Authorization/policyDefinitions/1f01b730-9b8a-4b6d-8b9a-b9b9b4b0c8f5"
    },
    {
      policyDefinitionReferenceId = "RequireCustomerManagedKey"
      policyDefinitionId          = "/providers/Microsoft.Authorization/policyDefinitions/9c1d7557-316e-4d51-b04d-791a94a69b83"
    },
    {
      policyDefinitionReferenceId = "AllowedADFRegions"
      policyDefinitionId          = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
      parameters = {
        listOfAllowedLocations = {
          value = var.allowed_regions
        }
      }
    }
  ]

  # Expose parameters the initiative expects to receive
  parameters = jsonencode({
    listOfAllowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed locations for ADF"
        description = "Regions where Azure Data Factory is allowed to be deployed."
      }
      defaultValue = var.allowed_regions
    }
  })
}

resource "azurerm_policy_assignment" "secure_adf_assignment" {
  name                 = var.policy_assignment_name
  display_name         = "Secure Azure Data Factory Baseline"
  description          = "Enforce secure ADF configuration (managed VNet, no public access, CMK, restricted regions)."
  policy_definition_id = azurerm_policy_set_definition.secure_adf_baseline.id

  scope            = "/subscriptions/${var.subscription_id}"
  enforcement_mode = var.enforcement_mode

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_regions
    }
  })
}
