# --- Control-plane identity info
data "azurerm_client_config" "current" {}

# --- Decide KV creation vs existing
locals {
  kv_name = replace("${var.name_prefix}-kv", "-", "")
  kv_id   = var.create_key_vault ? azurerm_key_vault.kv[0].id : var.key_vault_id
}

# --- Key Vault
resource "azurerm_key_vault" "kv" {
  count               = var.create_key_vault ? 1 : 0
  name                = local.kv_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
}

# --- Allow Terraform runner to manage secrets
resource "azurerm_role_assignment" "tf_kv_admin" {
  scope                = local.kv_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [azurerm_key_vault.kv]
}

# --- AKS WORKLOAD IDENTITY ACCESS (OIDC)
resource "azurerm_role_assignment" "workload_kv_access" {
  scope                = local.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_principal_id

  depends_on = [azurerm_key_vault.kv]
}

# --- Optional: extra read access
resource "azurerm_role_assignment" "extra_access" {
  for_each                         = toset(var.access_object_ids)
  scope                            = local.kv_id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = each.value
  skip_service_principal_aad_check = true

  depends_on = [azurerm_key_vault.kv]
}

# --- Wait for RBAC propagation
resource "time_sleep" "wait_for_rbac" {
  create_duration = "${var.rbac_wait_seconds}s"

  depends_on = [
    azurerm_role_assignment.tf_kv_admin,
    azurerm_role_assignment.workload_kv_access
  ]
}

# --- Seed secrets
resource "azurerm_key_vault_secret" "seed" {
  for_each     = tomap(nonsensitive(var.secrets))
  name         = each.key
  value        = each.value
  key_vault_id = local.kv_id

  depends_on = [time_sleep.wait_for_rbac]

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Optional SSH private key
resource "azurerm_key_vault_secret" "ssh_private_key" {
  count        = var.ssh_private_key == null ? 0 : 1
  name         = "ssh-private-key"
  value        = var.ssh_private_key
  key_vault_id = local.kv_id

  depends_on = [time_sleep.wait_for_rbac]

  lifecycle {
    ignore_changes = [value]
  }
}