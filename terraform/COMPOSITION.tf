# Root Composition
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# --------------------
# Resource Group
# --------------------
module "rg" {
  source   = "./modules/resource_group"
  name     = var.name_prefix == "" ? "rg" : "${var.name_prefix}-rg"
  location = var.location
}

# --------------------
# Network
# --------------------
module "network" {
  source       = "./modules/network"
  rg_name      = module.rg.name
  location     = module.rg.location
  name_prefix  = var.name_prefix
  trusted_cidr = "95.214.228.70/32"
}

# --------------------
# ACR
# --------------------
module "acr" {
  source        = "./modules/acr"
  rg_name       = module.rg.name
  location      = module.rg.location
  name_prefix   = var.name_prefix
  sku           = "Basic"
  name_override = var.acr_name
}

# --------------------
# Monitoring
# --------------------
module "monitoring" {
  source      = "./modules/monitoring"
  rg_name     = module.rg.name
  location    = module.rg.location
  name_prefix = var.name_prefix
}

# Identity Module (creates UAMI)
module "identity" {
  source              = "./modules/identity"
  name_prefix         = var.name_prefix
  resource_group_name = module.rg.name
  location            = module.rg.location
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:default:myapp-sa"
}

# --------------------
# AKS (OIDC ENABLED)
# --------------------
module "aks" {
  source              = "./modules/aks"
  resource_group_name = module.rg.name
  location            = module.rg.location
  name_prefix         = var.name_prefix
  dns_prefix          = var.dns_prefix
  node_vm_size        = "Standard_DS2_v2"
}

# ---- ACR Pull for kubelet identity ----
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = module.acr.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
  depends_on                       = [module.aks, module.acr]
}

# --------------------
# Compute
# --------------------
module "compute" {
  source           = "./modules/compute"
  create_vms       = var.create_vms
  enable_docker_vm = var.enable_docker_vm
  rg_name          = module.rg.name
  location         = module.rg.location
  name_prefix      = var.name_prefix
  subnet_id        = module.network.subnet_id
  admin_username   = var.admin_username
  ssh_public_key   = var.ssh_public_key
  trusted_cidr     = "95.214.228.70/32"
}

# --------------------
# Key Vault (OIDC‑BASED, NO SP)
# --------------------
module "kv" {
  source              = "./modules/key_vault"
  resource_group_name = module.rg.name
  location            = module.rg.location
  name_prefix         = var.name_prefix

  workload_identity_principal_id = module.identity.principal_id
  workload_identity_client_id    = module.identity.client_id
  workload_identity_id           = module.identity.id

  create_key_vault = true

  secrets           = var.secrets
  ssh_private_key   = var.ssh_private_key
  access_object_ids = var.access_object_ids
  rbac_wait_seconds = 60
}

# --------------------
# AKV CSI SecretProviderClass (OIDC / Workload Identity)
# --------------------


resource "kubectl_manifest" "secretproviderclass" {
  yaml_body = templatefile(
    "${path.root}/../k8s/csi/secretproviderclass.yaml.tftpl",
    {
      # MUST be the workload identity CLIENT ID
      client_id     = module.identity.client_id
      tenant_id     = data.azurerm_client_config.current.tenant_id
      keyvault_name = module.kv.kv_name
    }
  )

  depends_on = [
    module.aks,
    module.kv
  ]
}

# --------------------
# Outputs
# --------------------
output "key_vault_id" {
  value       = module.kv.kv_id
  description = "Resource ID of the Key Vault in use."
}

output "workload_identity_client_id" {
  value       = module.identity.client_id
  description = "Client ID used by AKS Workload Identity."
}
