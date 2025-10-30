locals {
  identity_config = var.identity == null ? null : {
    raw_type                   = trimspace(try(var.identity.type, ""))
    enable_system_assigned     = try(var.identity.enable_system_assigned_identity, null)
    user_assigned_identity_ids = try(var.identity.user_assigned_identity_ids, [])
    cmk_user_assigned_identity_id = (
      trimspace(try(var.identity.customer_managed_key_identity_id, "")) == ""
      ? null
      : trimspace(var.identity.customer_managed_key_identity_id)
    )
  }

  identity_type_tokens_raw = local.identity_config == null ? [] : (
    length(local.identity_config.raw_type) > 0
    ? distinct(compact([
      for token in split(",", local.identity_config.raw_type) :
      lookup({
        "systemassigned" = "SystemAssigned",
        "system"         = "SystemAssigned",
        "userassigned"   = "UserAssigned",
        "user"           = "UserAssigned",
      }, lower(trim(token)), null)
    ]))
    : compact([
      local.identity_config.enable_system_assigned == null
      ? null
      : (local.identity_config.enable_system_assigned ? "SystemAssigned" : null),
      length(local.identity_config.user_assigned_identity_ids) > 0 ? "UserAssigned" : null
    ])
  )

  identity_type_tokens = [
    for token in ["SystemAssigned", "UserAssigned"] : token
    if contains(local.identity_type_tokens_raw, token)
  ]

  identity_type = length(local.identity_type_tokens) == 0 ? null : join(", ", local.identity_type_tokens)

  identity_user_assigned_identity_ids = local.identity_config == null ? [] : [
    for id in local.identity_config.user_assigned_identity_ids : trimspace(id)
    if trimspace(id) != ""
  ]
  use_system_assigned_identity = contains(local.identity_type_tokens, "SystemAssigned")
  use_user_assigned_identity   = contains(local.identity_type_tokens, "UserAssigned")

  customer_managed_key_supplied = var.customer_managed_key_id != null && trimspace(var.customer_managed_key_id) != ""
  use_customer_managed_key      = local.customer_managed_key_supplied || contains(["pre", "prod"], lower(var.environment))

  customer_managed_key_input = !local.use_customer_managed_key ? null : (
    var.customer_managed_key_id == null ? null : trimspace(var.customer_managed_key_id)
  )
  customer_managed_key_sanitized = local.customer_managed_key_input == null ? null : trimsuffix(local.customer_managed_key_input, "/")

  customer_managed_key_versionless_id = local.customer_managed_key_sanitized == null ? null : (
    can(regex("/keys/[^/]+/[^/]+$", local.customer_managed_key_sanitized))
    ? replace(local.customer_managed_key_sanitized, "/[^/]+$", "")
    : local.customer_managed_key_sanitized
  )

  # Prefer UserAssigned when CMK is enabled; fall back to SystemAssigned
  customer_managed_key_identity_type = !local.use_customer_managed_key ? null : (
    local.use_user_assigned_identity ? "UserAssigned" : (
      local.use_system_assigned_identity ? "SystemAssigned" : null
    )
  )

  customer_managed_key_identity_override = trimspace(coalesce(var.customer_managed_key_identity_id, ""))

  customer_managed_key_identity_id_candidates = compact([
    local.customer_managed_key_identity_override,
    local.identity_config == null ? null : local.identity_config.cmk_user_assigned_identity_id,
    length(local.identity_user_assigned_identity_ids) > 0 ? local.identity_user_assigned_identity_ids[0] : null,
  ])

  customer_managed_key_identity_id = (local.customer_managed_key_identity_type == "UserAssigned" && length(local.customer_managed_key_identity_id_candidates) > 0) ? local.customer_managed_key_identity_id_candidates[0] : null
}

locals {
  # Names for networking resources created by this module
  subnet_name    = "${var.factory_name}-subnet"
  subnet_pe_name = "${var.factory_name}-pe"
  nsg            = { name = "${var.factory_name}-nsg" }
  tags           = var.tags
}
