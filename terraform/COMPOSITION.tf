# Root Composition
data "azurerm_subscription" "current" {}


# Foundational modules
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

  # NEW: pass the same trusted CIDR you use for compute
  trusted_cidr = "45.159.88.70/32"
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


# Compute (reuse shared NSG from network)
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

  # Restrict inbound to your trusted endpoint
  trusted_cidr = "45.159.88.70/32"

  # Reuse NSG created in the network layer (preferred)
  
  
  # nsg_name not needed when reusing
}


# Key Vault + SP module (enhanced)
module "kv" {
  source      = "./modules/key_vault"
  rg_name     = module.rg.name
  location    = module.rg.location
  name_prefix = var.name_prefix

  # Azure AD app/SP
  sp_display_name = "${var.name_prefix}-spn"

  # Allow Terraform runner identity to write secrets (data-plane)
  sp_object_id = var.sp_object_id

  # KV behaviour (create or use existing)
  create_key_vault = true
  # key_vault_id   = "<existing kv id>"  # if create_key_vault = false

  # Secrets to seed
  secrets         = var.secrets
  ssh_private_key = var.ssh_private_key

  # Optional extra read identities
  access_object_ids = var.access_object_ids

  # RBAC propagation wait
  rbac_wait_seconds = 60

  # === SP management-plane roles ===
  # Scope to assign roles at (choose one):
  # sp_role_assignment_scope = module.rg.id                       # narrow: RG scope
  sp_role_assignment_scope = data.azurerm_subscription.current.id # broad: subscription scope

  assign_contributor       = true
  assign_user_access_admin = true
  extra_role_assignments   = var.extra_role_assignments
}


# Convenience outputs (like example)
output "client_id" {
  value       = module.kv.application_id
  description = "Client ID of the created Azure AD application."
}

output "secret_name" {
  value       = module.kv.client_secret_name
  description = "Name of the KV secret holding the client secret."
}

output "key_vault_id" {
  value       = module.kv.kv_id
  description = "Resource ID of the Key Vault in use."
}