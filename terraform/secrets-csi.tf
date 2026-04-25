resource "local_file" "secretproviderclass" {
  filename = "${path.module}/../k8s/csi/secretproviderclass.yaml"

  content = templatefile(
    "${path.module}/../k8s/csi/secretproviderclass.yaml.tftpl",
    {
      client_id = module.identity.uami_client_id
      tenant_id = data.azurerm_client_config.current.tenant_id
      keyvault_name = module.kv.kv_name
    }
  )

  depends_on = [
    module.aks
  ]
}