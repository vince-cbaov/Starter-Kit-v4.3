resource "azurerm_key_vault" "kv" {
  name                       = replace("${var.name_prefix}kv", "-", "")
  location                   = var.location
  resource_group_name        = var.rg_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"

  # Retention / protection
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  # ❗ Choose ONE model:
  # enable_rbac_authorization = true   # If you prefer Azure RBAC (recommended for new builds)
  # …OR keep it false/omitted and use access policies below
}

# Access policies model (use ONLY if enable_rbac_authorization=false or omitted)
resource "azurerm_key_vault_access_policy" "access" {
  for_each     = toset(var.access_object_ids)
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = each.value

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

resource "azurerm_key_vault_secret" "seed" {
  for_each    = var.secrets
  name        = each.key
  value       = each.value
  key_vault_id = azurerm_key_vault.kv.id

  # optional:
  # content_type = "text/plain"
  # tags         = { source = "terraform" }
}

output "kv_name" {
  value = azurerm_key_vault.kv.name
}
