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
  source        = "./modules/aks"
  rg_name       = module.rg.name
  location      = module.rg.location
  name_prefix   = var.name_prefix
  node_vm_size  = "Standard_DS2_v2"
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.acr_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}

module "kv" {
  source      = "./modules/key_vault"
  rg_name     = module.rg.name
  location    = module.rg.location
  name_prefix = var.name_prefix
<<<<<<< HEAD
<<<<<<< HEAD
=======
  tenant_id   = var.tenant_id
>>>>>>> origin/dev

  secrets = {
    "acr-sp-app-id" = var.sp_app_id
    "acr-sp-secret" = var.sp_secret
    "tenant-id"     = var.tenant_id
    "acr-name"      = var.acr_name
  }
<<<<<<< HEAD
=======
  tenant_id   = var.tenant_id

  secrets = {
    "acr-sp-app-id" = var.sp_app_id
    "acr-sp-secret" = var.sp_secret
    "tenant-id"     = var.tenant_id
    "acr-name"      = var.acr_name
  }

>>>>>>> origin/main
=======

>>>>>>> origin/dev
  access_object_ids = []
}

module "compute" {
  source           = "./modules/compute"
  create_vms       = var.create_vms
  enable_docker_vm = var.enable_docker_vm
<<<<<<< HEAD
<<<<<<< HEAD

  rg_name        = module.rg.name
  location       = module.rg.location
  name_prefix    = var.name_prefix
  subnet_id      = module.network.subnet_id
  admin_username = var.admin_username
  ssh_public_key = var.ssh_public_key
}
=======
=======
>>>>>>> origin/dev
  rg_name          = module.rg.name
  location         = module.rg.location
  name_prefix      = var.name_prefix
  subnet_id        = module.network.subnet_id
  admin_username   = var.admin_username
  ssh_public_key   = var.ssh_public_key
}
<<<<<<< HEAD
<<<<<<< HEAD
``
>>>>>>> origin/main
=======
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
=======
>>>>>>> origin/dev
