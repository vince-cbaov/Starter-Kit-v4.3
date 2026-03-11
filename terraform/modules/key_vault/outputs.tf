# modules/key_vault/outputs.tf

output "kv_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "kv_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "kv_uri" {
  description = "Vault URI (https://skdevkv.vault.azure.net/)"
  value       = azurerm_key_vault.kv.vault_uri
}