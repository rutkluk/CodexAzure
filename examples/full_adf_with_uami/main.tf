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

variable "resource_group_name" {
  type    = string
  default = "rg-demo"
}
variable "location" {
  type    = string
  default = "westeurope"
}
variable "factory_name" {
  type    = string
  default = "df-demo"
}
variable "vnet_name" {
  type    = string
  default = "vnet-demo"
}
variable "subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}
variable "subnet_pe_cidr" {
  type    = string
  default = "10.10.2.0/24"
}
variable "enable_cmk" {
  type    = bool
  default = false
}
variable "key_vault_id" {
  type    = string
  default = null
}
variable "customer_managed_key_id" {
  type    = string
  default = null
}
variable "action_group_ids" {
  type    = list(string)
  default = []
}
variable "log_analytics_workspace_id" {
  type    = string
  default = null
}
variable "pipeline_file" {
  type    = string
  default = null
}
variable "pipeline_folder" {
  type    = string
  default = "demo"
}

locals {
  kv_id               = var.enable_cmk ? var.key_vault_id : null
  cmk_id              = var.enable_cmk ? var.customer_managed_key_id : null
  pipeline_file_path  = coalesce(var.pipeline_file, "${path.module}/pipeline_sample.json")
  diagnostic_settings = var.log_analytics_workspace_id == null ? null : {
    log_analytics_workspace_id = var.log_analytics_workspace_id
    logs                       = [{ category = "PipelineRuns" }, { category = "TriggerRuns" }]
    metrics                    = [{ category = "AllMetrics", enabled = true }]
  }
}

# User-assigned managed identity for ADF and CMK
module "uami" {
  source              = "../../modules/user_assigned_identity"
  name                = "uami-${var.factory_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Azure Data Factory (component) with UAMI, optional CMK, and default private endpoints
module "data_factory" {
  source = "../../components/data_factory/default"

  factory_name        = var.factory_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # Identity: use UAMI for ADF and CMK
  identity = {
    type                             = "UserAssigned"
    user_assigned_identity_ids       = [module.uami.id]
    customer_managed_key_identity_id = module.uami.id
  }

  # Optional CMK
  key_vault_id                               = local.kv_id
  customer_managed_key_id                    = local.cmk_id
  customer_managed_key_identity_principal_id = var.enable_cmk ? module.uami.principal_id : null

  # Networking (example subnets for ADF and control-plane PE)
  subnet = {
    resource_group_name = var.resource_group_name
    vnet_name           = var.vnet_name
    cidr                = var.subnet_cidr
  }
  subnet_pe = {
    resource_group_name = var.resource_group_name
    vnet_name           = var.vnet_name
    cidr                = var.subnet_pe_cidr
  }
}

# Optional: ADF credentials using UAMI
module "adf_credentials" {
  source          = "../../components/data_factory/modules/credentials"
  data_factory_id = module.data_factory.data_factory_id

  credentials_uami = {
    primary = { identity_id = module.uami.id }
  }
}

# Optional: ADF pipeline from JSON file
module "pipelines" {
  source          = "../../components/data_factory/modules/pipelines"
  data_factory_id = module.data_factory.data_factory_id

  pipelines = {
    sample = {
      name      = "pl-sample"
      file_path = local.pipeline_file_path
      folder    = var.pipeline_folder
    }
  }
}

# Optional: Alerts and diagnostics for ADF
module "alerts_and_metrics" {
  source              = "../../components/data_factory/modules/alerts_and_metrics"
  data_factory_id     = module.data_factory.data_factory_id
  resource_group_name = var.resource_group_name

  action_group_ids = var.action_group_ids

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
  }

  diagnostic = local.diagnostic_settings
}
