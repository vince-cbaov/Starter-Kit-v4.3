

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.name_prefix}-uami"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "myapp_fic" {
  name      = "myapp-fic"
  audience  = ["api://AzureADTokenExchange"]
  issuer    = var.issuer
  subject   = var.subject
  parent_id = azurerm_user_assigned_identity.workload.id
}