locals {
  normalized_pipelines = {
    for key, p in var.pipelines :
    key => {
      name        = coalesce(try(p.name, null), key)
      json        = try(p.json, null)
      file_path   = try(p.file_path, null)
      annotations = try(p.annotations, null)
      folder      = try(p.folder, null)
      parameters  = try(p.parameters, null)
      variables   = try(p.variables, null)
      additional  = try(p.additional_properties, null)
    }
  }
  pipelines_with_source = {
    for k, p in local.normalized_pipelines : k => merge(p, {
      resolved_json = p.json != null ? p.json : (p.file_path != null ? file(p.file_path) : null)
    })
  }
}