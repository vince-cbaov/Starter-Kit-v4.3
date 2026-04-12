resource "local_file" "secretproviderclass" {
  filename = "${path.module}/../k8s/csi/secretproviderclass.yaml"

  content = templatefile(
    "${path.module}/../k8s/csi/secretproviderclass.yaml.tftpl",
    {
      client_id = azurerm_user_assigned_identity.workload.client_id
      tenant_id = data.azurerm_client_config.current.tenant_id
    }
  )

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}