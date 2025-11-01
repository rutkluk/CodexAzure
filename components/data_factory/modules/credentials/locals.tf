locals {
  normalized_uami_credentials = {
    for key, cred in var.credentials_uami : key => {
      name        = try(trimspace(cred.name), "") != "" ? cred.name : key
      identity_id = trimspace(cred.identity_id)
      annotations = try(cred.annotations, null)
    }
  }
}