resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "sk-dev-uami"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "aks_federation" {
  name                = "sk-dev-aks-fed-cred"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id

  issuer   = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject  = "system:serviceaccount:starterkit:myapp-sa"
  audience = ["api://AzureADTokenExchange"]
}

resource "azurerm_federated_identity_credential" "myapp_fic" {
  name                = "sk-dev-myapp-fic"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id

  issuer   = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject  = "system:serviceaccount:default:myapp-sa"
  audience = ["api://AzureADTokenExchange"]
}