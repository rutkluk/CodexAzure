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

locals {
  metric_namespace = coalesce(try(var.metric_namespace, null), "Microsoft.DataFactory/factories")

  normalized_metric_alerts = {
    for key, v in var.metric_alerts :
    key => {
      name         = coalesce(try(v.name, null), key)
      description  = try(v.description, null)
      enabled      = try(v.enabled, true)
      severity     = try(v.severity, 3)
      metric_name  = v.metric_name
      aggregation  = v.aggregation
      operator     = v.operator
      threshold    = v.threshold
      frequency    = v.frequency
      window_size  = v.window_size
      dimensions   = try(v.dimensions, [])
    }
  }

  create_diagnostic = try(var.diagnostic, null) != null && (
    try(var.diagnostic.log_analytics_workspace_id, null) != null ||
    try(var.diagnostic.storage_account_id, null) != null ||
    try(var.diagnostic.eventhub_authorization_rule_id, null) != null
  )
}

resource "azurerm_monitor_metric_alert" "this" {
  for_each = local.normalized_metric_alerts

  name                = each.value.name
  description         = each.value.description
  severity            = each.value.severity
  enabled             = each.value.enabled
  frequency           = each.value.frequency
  window_size         = each.value.window_size
  scopes              = [var.data_factory_id]
  auto_mitigate       = try(var.auto_mitigate, null)
  target_resource_type = "Microsoft.DataFactory/factories"
  resource_group_name = var.resource_group_name

  dynamic "criteria" {
    for_each = [1]
    content {
      metric_name      = each.value.metric_name
      metric_namespace = local.metric_namespace
      aggregation      = each.value.aggregation
      operator         = each.value.operator
      threshold        = each.value.threshold

      dynamic "dimension" {
        for_each = each.value.dimensions
        content {
          name     = dimension.value.name
          operator = dimension.value.operator
          values   = dimension.value.values
        }
      }
    }
  }

  dynamic "action" {
    for_each = toset(var.action_group_ids)
    content {
      action_group_id = action.value
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = local.create_diagnostic ? 1 : 0

  name                       = coalesce(try(var.diagnostic.name, null), "adf-diagnostics")
  target_resource_id         = var.data_factory_id
  log_analytics_workspace_id = try(var.diagnostic.log_analytics_workspace_id, null)
  storage_account_id         = try(var.diagnostic.storage_account_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic.eventhub_authorization_rule_id, null)
  eventhub_name              = try(var.diagnostic.eventhub_name, null)

  dynamic "enabled_log" {
    for_each = try(var.diagnostic.logs, [])
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = try(var.diagnostic.metrics, [
      { category = "AllMetrics", enabled = true }
    ])
    content {
      category = try(metric.value.category, "AllMetrics")
      enabled  = try(metric.value.enabled, true)
    }
  }
}
