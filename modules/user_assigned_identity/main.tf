terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.37.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  role_assignments = {
    for idx, ra in var.role_assignments : tostring(idx) => {
      scope                = ra.scope
      role_definition_id   = try(ra.role_definition_id, null)
      role_definition_name = try(ra.role_definition_name, null)
      condition            = try(ra.condition, null)
      condition_version    = try(ra.condition_version, null)
    }
  }
}

data "azurerm_role_definition" "by_name" {
  for_each = {
    for k, v in local.role_assignments : k => v
    if v.role_definition_id == null && v.role_definition_name != null
  }
  name  = each.value.role_definition_name
  scope = each.value.scope
}

resource "azurerm_role_assignment" "assign_by_id" {
  for_each = {
    for k, v in local.role_assignments : k => v
    if v.role_definition_id != null
  }

  scope              = each.value.scope
  role_definition_id = each.value.role_definition_id
  principal_id       = azurerm_user_assigned_identity.this.principal_id

  skip_service_principal_aad_check = true

  condition         = try(each.value.condition, null)
  condition_version = try(each.value.condition_version, null)
}

resource "azurerm_role_assignment" "assign_by_name" {
  for_each = data.azurerm_role_definition.by_name

  scope              = each.value.scope
  role_definition_id = each.value.id
  principal_id       = azurerm_user_assigned_identity.this.principal_id

  skip_service_principal_aad_check = true

  condition         = try(local.role_assignments[each.key].condition, null)
  condition_version = try(local.role_assignments[each.key].condition_version, null)
}

