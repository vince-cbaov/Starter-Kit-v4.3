

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.name_prefix}-uami"
  resource_group_name = var.resource_group_name
  location            = var.location

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_federated_identity_credential" "myapp_fic" {
  name     = "myapp-fic"
  audience = ["api://AzureADTokenExchange"]
  issuer   = var.aks_oidc_issuer_url
  #subject                   = var.subject
  subject                   = "system:serviceaccount:default:myapp-sa"
  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id
}

