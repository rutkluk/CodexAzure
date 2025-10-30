variable "data_factory_id" {
  description = "Resource ID of the target Data Factory."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to host the metric alerts."
  type        = string
}

variable "metric_namespace" {
  description = "Metric namespace to use for metric alerts. Defaults to Microsoft.DataFactory/factories."
  type        = string
  default     = null
}

variable "action_group_ids" {
  description = "List of Azure Monitor Action Group IDs to attach to metric alerts."
  type        = list(string)
  default     = []
}

variable "auto_mitigate" {
  description = "Optional flag to enable auto-mitigation for metric alerts."
  type        = bool
  default     = null
}

variable "metric_alerts" {
  description = "Map of metric alert definitions."
  type = map(object({
    name        = optional(string)
    description = optional(string)
    enabled     = optional(bool)
    severity    = optional(number)

    metric_name = string
    aggregation = string
    operator    = string
    threshold   = number
    frequency   = string   # ISO8601 duration e.g. PT5M
    window_size = string   # ISO8601 duration e.g. PT5M

    dimensions = optional(list(object({
      name     = string
      operator = string
      values   = list(string)
    })), [])
  }))
  default = {}
}

variable "diagnostic" {
  description = "Optional diagnostic settings to route logs/metrics."
  type = object({
    name                           = optional(string)
    log_analytics_workspace_id     = optional(string)
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    logs = optional(list(object({
      category = string
      enabled  = optional(bool)
    })), [])
    metrics = optional(list(object({
      category = optional(string)
      enabled  = optional(bool)
    })), [])
  })
  default = null
}
