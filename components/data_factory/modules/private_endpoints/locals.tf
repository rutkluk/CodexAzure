locals {
  normalized_endpoints = {
    for key, ep in var.endpoints : key => {
      name               = coalesce(try(ep.name, null), key)
      target_resource_id = trimspace(ep.target_resource_id)
      subresource_name   = trimspace(ep.subresource_name)
      description        = try(ep.description, null)
    }
  }
}