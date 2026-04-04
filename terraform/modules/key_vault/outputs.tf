output "kv_name" {
  description = "Name of the Key Vault."
  value       = try(azurerm_key_vault.kv[0].name, null)
}

output "kv_id" {
  description = "Resource ID of the Key Vault in use."
  value       = try(azurerm_key_vault.kv[0].id, null)
}

output "kv_uri" {
  description = "Vault URI."
  value       = try(azurerm_key_vault.kv[0].vault_uri, null)
}

output "uami_principal_id" {
  value = azurerm_user_assigned_identity.workload_id.principal_id
}

output "uami_client_id" {
  value = azurerm_user_assigned_identity.workload_id.client_id
}

output "uami_id" {
  value = azurerm_user_assigned_identity.workload_id.id
}