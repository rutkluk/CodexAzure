variable "data_factory_id" {
  description = "ID docelowej fabryki danych ADF."
  type        = string
}

variable "pipelines" {
  description = "Mapa definicji pipeline. Dla kazdego elementu podaj `json` lub `file_path`."
  type = map(object({
    name                  = optional(string)
    json                  = optional(string)
    file_path             = optional(string)
    annotations           = optional(list(string))
    folder                = optional(string)
    parameters            = optional(map(any))
    variables             = optional(map(any))
    additional_properties = optional(map(string))
  }))
}

