resource "azurerm_user_assigned_identity" "workload_id" {
  name                = "aks-workload-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "aks_federation" {
  name                = "aks-federated-cred"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload_id.id

  issuer   = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject  = "system:serviceaccount:starterkit:myapp-sa"
  audience = ["api://AzureADTokenExchange"]
}
