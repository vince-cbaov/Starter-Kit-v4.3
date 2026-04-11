# ============================================================
# Root Composition
# ============================================================

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

# --------------------
# Identity (UAMI for Workload Identity)
# --------------------
module "identity" {
  source              = "./modules/identity"
  name_prefix         = var.name_prefix
  resource_group_name = module.rg.name
  location            = module.rg.location

  issuer  = module.aks.oidc_issuer_url
  subject = "system:serviceaccount:default:myapp-sa"
}

# --------------------
# ACR Pull for AKS kubelet
# --------------------
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = module.acr.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true

  depends_on = [
    module.aks,
    module.acr
  ]
}

# --------------------
# Key Vault (OIDC / Workload Identity)
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
# Compute (Jenkins + Docker VMs)
# --------------------
module "compute" {
  source           = "./modules/compute"
  create_vms       = var.create_vms
  enable_docker_vm = var.enable_docker_vm

  rg_name        = module.rg.name
  location       = module.rg.location
  name_prefix    = var.name_prefix
  subnet_id      = module.network.subnet_id
  admin_username = var.admin_username
  ssh_public_key = var.ssh_public_key
  trusted_cidr   = "95.214.228.70/32"

  # REQUIRED: passed from Key Vault module
  key_vault_id = module.kv.kv_id

  
  depends_on = [
    time_sleep.kv_rbac_wait
  ]
}

# --------------------
# AKV CSI SecretProviderClass (OIDC / Workload Identity)
# --------------------
resource "kubectl_manifest" "secretproviderclass" {
  yaml_body = templatefile(
    "${path.root}/../k8s/csi/secretproviderclass.yaml.tftpl",
    {
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
# Role Assignments for Docker / AKS
# --------------------
resource "azurerm_role_assignment" "docker_acr_push" {
  count                = var.enable_docker_vm ? 1 : 0
  scope                = module.acr.acr_id
  role_definition_name = "AcrPush"
  principal_id         = module.identity.principal_id
}

resource "azurerm_role_assignment" "docker_aks_admin" {
  count                = var.enable_docker_vm ? 1 : 0
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = module.identity.principal_id
}

resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = module.kv.kv_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id

  depends_on = [
    module.kv
  ]
}

# Wait for RBAC propagation before creating secrets or Docker VM
resource "time_sleep" "kv_rbac_wait" {
  depends_on = [
    azurerm_role_assignment.terraform_kv_secrets_officer
  ]

  create_duration = "180s"
}
