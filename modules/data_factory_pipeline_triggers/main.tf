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
  normalized_triggers = {
    for key, value in var.triggers :
    key => merge(value, {
      type                 = lower(value.type)
      name                 = coalesce(try(value.name, null), key)
      activated            = try(value.activated, true)
      pipeline_parameters  = try(value.pipeline_parameters, null)
      annotations          = try(value.annotations, null)
      description          = try(value.description, null)
      additional_properties = try(value.additional_properties, null)
    })
  }

  schedule_triggers = {
    for key, value in local.normalized_triggers :
    key => value if value.type == "schedule"
  }

  tumbling_window_triggers = {
    for key, value in local.normalized_triggers :
    key => value if value.type == "tumbling_window"
  }
}

resource "azurerm_data_factory_trigger_schedule" "this" {
  for_each = local.schedule_triggers

  name            = each.value.name
  data_factory_id = var.data_factory_id
  pipeline_name   = each.value.pipeline_name

  activated            = each.value.activated
  annotations          = each.value.annotations
  description          = each.value.description
  pipeline_parameters  = each.value.pipeline_parameters
  additional_properties = each.value.additional_properties

  dynamic "schedule" {
    for_each = try(each.value.schedule, null) == null ? [] : [each.value.schedule]
    content {
      frequency     = schedule.value.frequency
      interval      = try(schedule.value.interval, null)
      start_time    = try(schedule.value.start_time, null)
      end_time      = try(schedule.value.end_time, null)
      time_zone     = try(schedule.value.time_zone, null)
      days_of_month = try(schedule.value.days_of_month, null)
      days_of_week  = try(schedule.value.days_of_week, null)
      hours         = try(schedule.value.hours, null)
      minutes       = try(schedule.value.minutes, null)

      dynamic "monthly_occurrence" {
        for_each = try(schedule.value.monthly_occurrence, [])
        content {
          day        = monthly_occurrence.value.day
          occurrence = monthly_occurrence.value.occurrence
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.schedule, null) != null
      error_message = "Schedule triggers require a schedule configuration block."
    }

    precondition {
      condition     = try(each.value.schedule.frequency, null) != null
      error_message = "schedule.frequency is required for schedule triggers."
    }
  }
}

resource "azurerm_data_factory_trigger_tumbling_window" "this" {
  for_each = local.tumbling_window_triggers

  name            = each.value.name
  data_factory_id = var.data_factory_id
  pipeline_name   = each.value.pipeline_name

  frequency     = each.value.frequency
  interval      = each.value.interval
  start_time    = each.value.start_time
  end_time      = try(each.value.end_time, null)
  delay         = try(each.value.delay, null)
  max_concurrency = try(each.value.max_concurrency, null)
  activated     = each.value.activated
  annotations   = each.value.annotations
  description   = each.value.description
  pipeline_parameters  = each.value.pipeline_parameters
  additional_properties = each.value.additional_properties

  dynamic "retry" {
    for_each = try(each.value.retry, null) == null ? [] : [each.value.retry]
    content {
      count               = try(retry.value.count, null)
      interval_in_seconds = try(retry.value.interval_in_seconds, null)
    }
  }

  lifecycle {
    precondition {
      condition     = try(each.value.frequency, null) != null && try(each.value.interval, null) != null && try(each.value.start_time, null) != null
      error_message = "Tumbling window triggers require frequency, interval, and start_time values."
    }
  }
}
