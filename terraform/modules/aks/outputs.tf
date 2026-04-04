output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config[0]
  sensitive = true
}

output "name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Principal ID (used for RBAC, Key Vault, ACR, etc.)
output "workload_identity_principal_id" {
  value       = azurerm_user_assigned_identity.workload_identity.principal_id
  description = "Principal ID of the AKS workload identity."
}

# Client ID (used by CSI driver / SDKs)
output "workload_identity_client_id" {
  value       = azurerm_user_assigned_identity.workload_identity.client_id
  description = "Client ID of the AKS workload identity."
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