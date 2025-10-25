locals {
  identity_config = var.identity == null ? null : {
    enable_system_assigned_identity = try(var.identity.enable_system_assigned_identity, false)
    user_assigned_identity_ids      = try(var.identity.user_assigned_identity_ids, [])
  }

  identity_type_tokens = local.identity_config == null ? [] : compact([
    local.identity_config.enable_system_assigned_identity ? "SystemAssigned" : null,
    length(local.identity_config.user_assigned_identity_ids) > 0 ? "UserAssigned" : null,
  ])

  identity_type = length(local.identity_type_tokens) == 0 ? null : join(", ", local.identity_type_tokens)

  identity_user_assigned_identity_ids = local.identity_config == null ? [] : local.identity_config.user_assigned_identity_ids
  use_system_assigned_identity        = contains(local.identity_type_tokens, "SystemAssigned")
  use_user_assigned_identity          = contains(local.identity_type_tokens, "UserAssigned")

  customer_managed_key_supplied = var.customer_managed_key_id != null && trimspace(var.customer_managed_key_id) != ""
  use_customer_managed_key       = local.customer_managed_key_supplied || contains(["pre", "prod"], lower(var.environment))

  customer_managed_key_input = !local.use_customer_managed_key ? null : trimspace(var.customer_managed_key_id)
  customer_managed_key_sanitized = local.customer_managed_key_input == null
    ? null
    : trimsuffix(local.customer_managed_key_input, "/")

  customer_managed_key_versionless_id = local.customer_managed_key_sanitized == null
    ? null
    : (
      can(regex("/keys/[^/]+/[^/]+$", local.customer_managed_key_sanitized))
      ? replace(local.customer_managed_key_sanitized, "/[^/]+$", "")
      : local.customer_managed_key_sanitized
    )

  customer_managed_key_identity_type = !local.use_customer_managed_key ? null : (
    local.use_system_assigned_identity ? "SystemAssigned" : (
      local.use_user_assigned_identity ? "UserAssigned" : null
    )
  )

  customer_managed_key_identity_id = local.customer_managed_key_identity_type == "UserAssigned" && length(local.identity_user_assigned_identity_ids) > 0
    ? local.identity_user_assigned_identity_ids[0]
    : null
}
