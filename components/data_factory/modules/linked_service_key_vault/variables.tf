variable "name" {
  description = "Nazwa Linked Service do Key Vault."
  type        = string
}

variable "data_factory_id" {
  description = "ID fabryki danych ADF."
  type        = string
}

variable "key_vault_id" {
  description = "ID Key Vault, do ktorego laczy sie Linked Service."
  type        = string
}

variable "annotations" {
  description = "Opcjonalne adnotacje."
  type        = list(string)
  default     = null
}

variable "parameters" {
  description = "Opcjonalne parametry Linked Service."
  type        = map(any)
  default     = null
}

variable "integration_runtime_name" {
  description = "Opcjonalna nazwa Integration Runtime dla LS."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Czy utworzyc Linked Service (wewnetrzna flaga modulu)."
  type        = bool
  default     = true
}
