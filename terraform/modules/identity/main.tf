

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.name_prefix}-uami"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "myapp_fic" {
  name                = var.name_prefix != "" ? "${var.name_prefix}-fic" : "myapp-fic"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  issuer              = var.issuer
  subject             = var.subject
  audience            = ["api://AzureADTokenExchange"]
}