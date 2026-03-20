module "rg" {
  source   = "./modules/resource_group"
  name     = var.name_prefix == "" ? "rg" : "${var.name_prefix}-rg"
  location = var.location
}

module "network" {
  source      = "./modules/network"
  rg_name     = module.rg.name
  location    = module.rg.location
  name_prefix = var.name_prefix
}

module "acr" {
  source        = "./modules/acr"
  rg_name       = module.rg.name
  location      = module.rg.location
  name_prefix   = var.name_prefix
  sku           = "Basic"
  name_override = var.acr_name
}

module "monitoring" {
  source      = "./modules/monitoring"
  rg_name     = module.rg.name
  location    = module.rg.location
  name_prefix = var.name_prefix
}

module "aks" {
  source       = "./modules/aks"
  rg_name      = module.rg.name
  location     = module.rg.location
  name_prefix  = var.name_prefix
  node_vm_size = "Standard_DS2_v2"
}

# ---- AcrPull for the kubelet identity ----
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = module.acr.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
  depends_on                       = [module.aks, module.acr]
}

# ================================
# Key Vault Module (OPTION E2)
# Terraform seeds the secrets
# ================================
module "kv" {
  source      = "./modules/key_vault"
  rg_name     = module.rg.name
  location    = module.rg.location
  name_prefix = var.name_prefix

  # Who Terraform runs as (for KV RBAC write access)
  sp_object_id = var.sp_object_id

  # Tenant ID is still needed by the KV module
  tenant_id = var.tenant_id

  # ALL secrets for KV Option E2 now come from tfvars:
  secrets          = var.secrets
  ssh_private_key  = var.ssh_private_key

  # Optional extra access identities
  access_object_ids = var.access_object_ids
}

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
  trusted_cidr     = "45.159.88.70/32"
}