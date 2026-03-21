# --- Control-plane identity info
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

# --- Azure AD Application + Service Principal + Client Secret
resource "azuread_application" "app" {
  display_name = var.sp_display_name
}

resource "azuread_service_principal" "sp" {
  client_id = azuread_application.app.client_id
}

resource "azuread_service_principal_password" "sp_secret" {
  service_principal_id = azuread_service_principal.sp.id
  end_date_relative    = var.secret_end_date_relative
}

# --- Decide KV creation vs. existing
locals {
  kv_name_calc = var.key_vault_name_override != null ? var.key_vault_name_override : replace("${var.name_prefix}kv", "-", "")
}

resource "azurerm_key_vault" "kv" {
  count               = var.create_key_vault ? 1 : 0
  name                = local.kv_name_calc
  location            = var.location
  resource_group_name = var.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  rbac_authorization_enabled = true

  # Optional hardening (enable when you add private endpoints / network ACLs)
  # public_network_access_enabled = false

  # tags = {
  #   "managed-by" = "terraform"
  #   "component"  = "key-vault"
  # }
}

# Effective KV ID (created or provided)
locals {
  key_vault_id_effective = var.create_key_vault ? azurerm_key_vault.kv[0].id : var.key_vault_id
}

# --- Data-plane RBAC: allow Terraform's identity to WRITE secrets
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                            = local.key_vault_id_effective
  role_definition_name             = "Key Vault Secrets Officer"
  principal_id                     = var.sp_object_id
  skip_service_principal_aad_check = true

  # If creating KV, ensure the vault exists first
  depends_on = [azurerm_key_vault.kv]
}

# --- Optional: grant extra identities read of secret values
resource "azurerm_role_assignment" "extra_access" {
  for_each                         = toset(var.access_object_ids)
  scope                            = local.key_vault_id_effective
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = each.value
  skip_service_principal_aad_check = true
  depends_on                       = [azurerm_key_vault.kv]
}

# --- Wait for RBAC propagation before writing secrets
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.kv_secrets_officer]
  create_duration = "${var.rbac_wait_seconds}s"
}

# --- Store the SP client secret into Key Vault
resource "azurerm_key_vault_secret" "sp_client_secret" {
  name         = "sp-client-secret"
  value        = azuread_service_principal_password.sp_secret.value
  key_vault_id = local.key_vault_id_effective
  content_type = "application/x-azuread-client-secret"

  depends_on = [time_sleep.wait_for_rbac]

  lifecycle {
    # Avoid rotation noise in plans
    ignore_changes = [value]
  }
}

# --- Optional SSH private key
resource "azurerm_key_vault_secret" "ssh_private_key" {
  count        = var.ssh_private_key == null ? 0 : 1
  name         = "ssh-private-key"
  value        = var.ssh_private_key
  key_vault_id = local.key_vault_id_effective
  content_type = "application/x-openssh-private-key"

  depends_on = [time_sleep.wait_for_rbac]

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Seed the rest of the secrets (map)
resource "azurerm_key_vault_secret" "seed" {
  for_each     = tomap(nonsensitive(var.secrets))
  name         = each.key
  value        = each.value
  key_vault_id = local.key_vault_id_effective
  depends_on   = [time_sleep.wait_for_rbac]

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Management-plane roles for the created SP at the chosen scope
resource "azurerm_role_assignment" "sp_contributor" {
  count                = var.assign_contributor ? 1 : 0
  scope                = var.sp_role_assignment_scope
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp.object_id

  skip_service_principal_aad_check = true
  depends_on                       = [azuread_service_principal.sp]
}

resource "azurerm_role_assignment" "sp_user_access_admin" {
  count                = var.assign_user_access_admin ? 1 : 0
  scope                = var.sp_role_assignment_scope
  role_definition_name = "User Access Administrator"
  principal_id         = azuread_service_principal.sp.object_id

  skip_service_principal_aad_check = true
  depends_on                       = [azuread_service_principal.sp]
}

resource "azurerm_role_assignment" "sp_extra" {
  for_each             = { for i, r in var.extra_role_assignments : i => r }
  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azuread_service_principal.sp.object_id

  skip_service_principal_aad_check = true
  depends_on                       = [azuread_service_principal.sp]
}
