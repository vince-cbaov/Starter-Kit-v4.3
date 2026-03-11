resource "azurerm_key_vault" "kv" {
  name                       = replace("${var.name_prefix}kv", "-", "")
  location                   = var.location
  resource_group_name        = var.rg_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
}

resource "azurerm_key_vault_access_policy" "access" {
  for_each = toset(var.access_object_ids)

  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = var.tenant_id
  object_id    = each.value

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge",
    "Recover",
  ]
}

resource "azurerm_key_vault_secret" "seed" {
  for_each = var.secrets

  name          = each.key
  value         = each.value
  key_vault_id  = azurerm_key_vault.kv.id
}

output "kv_name" {
  value = azurerm_key_vault.kv.name
}
