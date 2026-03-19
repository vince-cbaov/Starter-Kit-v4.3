############################################
# Key Vault (RBAC mode) + Terraform-managed secrets
############################################

# Control-plane identity info
data "azurerm_client_config" "current" {}

# ----------------------------------------
# Key Vault resource (RBAC authorization)
# ----------------------------------------
resource "azurerm_key_vault" "kv" {
  name                = replace("${var.name_prefix}kv", "-", "")
  location            = var.location
  resource_group_name = var.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # Updated attribute name (new provider versions)
  rbac_authorization_enabled = true
}

# -----------------------------------------------------
# Data-plane RBAC: allow Terraform's identity to WRITE secrets
# -----------------------------------------------------
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"   # needed for write access
  principal_id         = var.sp_object_id              # who runs Terraform
  skip_service_principal_aad_check = true
}

# -----------------------------------------------------
# Wait for RBAC propagation before writing secrets
# -----------------------------------------------------
resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.kv_secrets_officer]
  create_duration = "30s"
}

# -----------------------------------------------------
# Terraform creates individual secret
# -----------------------------------------------------
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "ssh-private-key"
  value        = var.ssh_private_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_rbac]
}

# -----------------------------------------------------
# Terraform creates secret MAP (all other secrets)
# -----------------------------------------------------
resource "azurerm_key_vault_secret" "seed" {
  for_each     = var.secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [time_sleep.wait_for_rbac]
}

# -----------------------------------------------------
# Optional: grant extra identities access to secret values
# -----------------------------------------------------
resource "azurerm_role_assignment" "extra_access" {
  for_each            = toset(var.access_object_ids)
  scope               = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
  depends_on           = [azurerm_key_vault.kv]
}

# -----------------------------------------------------
# Outputs
# -----------------------------------------------------
output "id" {
  value = azurerm_key_vault.kv.id
}

output "name" {
  value = azurerm_key_vault.kv.name
}