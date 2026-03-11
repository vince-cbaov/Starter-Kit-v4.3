# =========================
# Key Vault (RBAC model)
# =========================
resource "azurerm_key_vault" "kv" {
<<<<<<< HEAD
<<<<<<< HEAD
  name                       = replace("${var.name_prefix}kv", "-", "")
  location                   = var.location
  resource_group_name        = var.rg_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
<<<<<<< HEAD
=======
  name                        = replace("${var.name_prefix}kv", "-", "")
  location                    = var.location
  resource_group_name         = var.rg_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
>>>>>>> origin/dev

  # Retention / protection
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  # Use Azure RBAC for data-plane authorization (recommended)
  rbac_authorization_enabled  = true
}

<<<<<<< HEAD
# Access policies model (use ONLY if enable_rbac_authorization=false or omitted)
resource "azurerm_key_vault_access_policy" "access" {
  for_each     = toset(var.access_object_ids)
=======
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
=======
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
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
}

=======
>>>>>>> origin/dev
# =========================
# RBAC role for the SP that runs Terraform
# - var.sp_object_id must be the *Object ID* of your service principal
# =========================
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"   # read/write secrets
  principal_id         = var.sp_object_id
}
<<<<<<< HEAD

<<<<<<< HEAD
>>>>>>> origin/main
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = each.value

  secret_permissions = [
<<<<<<< HEAD
    "Get", "List", "Set", "Delete", "Purge", "Recover"
=======
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover",
>>>>>>> origin/main
  ]
}

resource "azurerm_key_vault_secret" "seed" {
<<<<<<< HEAD
  for_each    = var.secrets
  name        = each.key
  value       = each.value
  key_vault_id = azurerm_key_vault.kv.id

  # optional:
  # content_type = "text/plain"
  # tags         = { source = "terraform" }
=======
  for_each = var.secrets

  name          = each.key
  value         = each.value
  key_vault_id  = azurerm_key_vault.kv.id
>>>>>>> origin/main
=======
# =========================
# Seed secrets
# =========================
resource "time_sleep" "wait_for_rbac" {
  depends_on = [azurerm_role_assignment.kv_secrets_officer]
  create_duration = "20s"
}

resource "azurerm_key_vault_secret" "seed" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_rbac]
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
}

  # Ensure RBAC assignment exists (prevents 403 race)
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

=======

# =========================
# Seed secrets
# =========================
resource "time_sleep" "wait_for_rbac" {
  depends_on = [azurerm_role_assignment.kv_secrets_officer]
  create_duration = "20s"
}

resource "azurerm_key_vault_secret" "seed" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_rbac]
}

  # Ensure RBAC assignment exists (prevents 403 race)
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

>>>>>>> origin/dev

