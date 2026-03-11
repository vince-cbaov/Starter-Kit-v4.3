# =========================
# Key Vault (RBAC model)
# =========================
resource "azurerm_key_vault" "kv" {
  name                        = replace("${var.name_prefix}kv", "-", "")
  location                    = var.location
  resource_group_name         = var.rg_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  # Retention / protection
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  # Use Azure RBAC for data-plane authorization (recommended)
  rbac_authorization_enabled  = true
}

# =========================
# RBAC role for the SP that runs Terraform
# - var.sp_object_id must be the *Object ID* of your service principal
# =========================
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"   # read/write secrets
  principal_id         = var.sp_object_id
}

# =========================
# Seed secrets
# =========================
resource "azurerm_key_vault_secret" "seed" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  # Ensure RBAC assignment exists (prevents 403 race)
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}