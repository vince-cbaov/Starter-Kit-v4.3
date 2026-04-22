output "id" {
  value = azurerm_user_assigned_identity.workload.id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.workload.principal_id
}

output "client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "uami_id" {
  value = azurerm_user_assigned_identity.workload.id
}

output "workload_uami_id" {
  description = "ID of the User Assigned Managed Identity for workload/Jenkins"
  value       = azurerm_user_assigned_identity.workload.id
}

output "uami_client_id" {
  value       = azurerm_user_assigned_identity.workload.client_id
  description = "Client ID of the AKS workload identity (required by CSI driver)"
}

output "uami_principal_id" {
  value = azurerm_user_assigned_identity.workload.principal_id
}
