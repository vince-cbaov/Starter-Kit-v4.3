output "kv_name" {
  description = "Name of the Key Vault (null if using existing and not derived here)."
  value       = try(azurerm_key_vault.kv[0].name, null)
}

output "kv_id" {
  description = "Resource ID of the Key Vault in use."
  value       = local.key_vault_id_effective
}

output "kv_uri" {
  description = "Vault URI (null if using existing and not derived here)."
  value       = try(azurerm_key_vault.kv[0].vault_uri, null)
}

output "application_id" {
  description = "Azure AD Application (Client) ID."
  value       = azuread_application.app.client_id
}

output "service_principal_object_id" {
  description = "Object ID of the created Service Principal."
  value       = azuread_service_principal.sp.object_id
}

output "tenant_id" {
  description = "Tenant ID from the current context."
  value       = data.azurerm_client_config.current.tenant_id
}

output "client_secret_kv_secret_id" {
  description = "Resource ID of the Key Vault secret that holds the SP client secret."
  value       = azurerm_key_vault_secret.sp_client_secret.id
}

output "client_secret_name" {
  description = "Name of the KV secret that holds the SP client secret."
  value       = azurerm_key_vault_secret.sp_client_secret.name
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload_id.client_id
}