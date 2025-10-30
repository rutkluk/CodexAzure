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

# Example: configure alerts and diagnostics for an existing Data Factory
module "alerts_and_metrics" {
  source = "../../components/data_factory/modules/alerts_and_metrics"

  # Replace with your Data Factory resource ID and RG
  data_factory_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.DataFactory/factories/df-demo"
  resource_group_name = "rg-demo"

  # Optional action groups to notify
  action_group_ids = [
    "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/microsoft.insights/actionGroups/ag-notify"
  ]

  # Two sample metric alerts
  metric_alerts = {
    failedActivities = {
      metric_name = "FailedActivityRuns"
      aggregation = "Total"
      operator    = "GreaterThan"
      threshold   = 0
      frequency   = "PT5M"
      window_size = "PT5M"
      severity    = 2
    }

    pipelineDurationHigh = {
      name        = "ADF-Pipeline-Duration-High"
      description = "Pipeline duration exceeded expected threshold"
      metric_name = "PipelineRunDuration"
      aggregation = "Average"
      operator    = "GreaterThan"
      threshold   = 1800   # seconds
      frequency   = "PT5M"
      window_size = "PT15M"
      severity    = 3

      dimensions = [
        {
          name     = "PipelineName"
          operator = "Include"
          values   = ["pl-nightly-refresh", "pl-hourly-window"]
        }
      ]
    }
  }

  # Optional: route diagnostics to Log Analytics and metrics category
  diagnostic = {
    name                       = "adf-diag"
    log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-demo/providers/Microsoft.OperationalInsights/workspaces/law-demo"
    logs = [
      { category = "PipelineRuns" },
      { category = "TriggerRuns" },
      { category = "ActivityRuns" }
    ]
    metrics = [
      { category = "AllMetrics", enabled = true }
    ]
  }
}

