# =========================
# Key Vault (RBAC only)
# =========================
resource "azurerm_key_vault" "kv" {
  name                        = replace("${var.name_prefix}kv", "-", "")
  location                    = var.location
  resource_group_name         = var.rg_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  # IMPORTANT: Use RBAC instead of access policies
  rbac_authorization_enabled  = true
}


# =========================
# RBAC role for the SP that runs Terraform
# =========================
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"   # Write secrets
  principal_id         = var.sp_object_id
}


# =========================
# Fix RBAC propagation delay (prevents 403)
# =========================
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.kv_secrets_officer]
  create_duration = "20s"
}


# =========================
# Seed Key Vault Secrets (RBAC only)
# =========================
resource "azurerm_key_vault_secret" "seed" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on   = [time_sleep.wait_for_rbac]
}
``
