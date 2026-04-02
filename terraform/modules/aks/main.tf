resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  dns_prefix          = "${var.name_prefix}-dns"
  location            = var.location
  resource_group_name = var.rg_name


  oidc_issuer_enabled = true

  default_node_pool {
    name       = "nodepool1"
    vm_size    = var.node_vm_size
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }
}

output "name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}