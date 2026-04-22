

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.name_prefix}-uami"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_federated_identity_credential" "myapp_fic" {
  name                      = "myapp-fic"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = var.aks_oidc_issuer_url
  subject                   = var.subject
  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id
}

resource "azurerm_role_assignment" "uami_subscription_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}