resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name_prefix == "" ? "aks" : "${var.name_prefix}-aks"
  dns_prefix          = "${var.name_prefix}-dns"
  location            = var.location
  resource_group_name = var.resource_group_name


  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name       = "nodepool1"
    vm_size    = var.node_vm_size
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }


  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
}

