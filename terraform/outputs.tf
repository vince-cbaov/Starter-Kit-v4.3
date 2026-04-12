############################################
# ROOT OUTPUTS — FINAL CLEAN VERSION
############################################

# --------------------
# Resource Group
# --------------------
output "rg_name" {
  description = "Name of the resource group"
  value       = module.rg.name
}

output "rg_location" {
  description = "Location of the resource group"
  value       = module.rg.location
}

# --------------------
# Key Vault
# --------------------
output "kv_name" {
  description = "Name of the Key Vault"
  value       = module.kv.kv_name
}

output "kv_uri" {
  description = "URI of the Key Vault"
  value       = module.kv.kv_uri
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = module.kv.kv_id
}

# --------------------
# ACR
# --------------------
output "acr_name" {
  description = "Azure Container Registry name"
  value       = module.acr.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server"
  value       = module.acr.login_server
}

# --------------------
# AKS
# --------------------
output "aks_name" {
  description = "AKS cluster name"
  value       = module.aks.name
}

output "kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = module.aks.kube_config
  sensitive   = true
}

# --------------------
# Compute
# --------------------
output "docker_vm_ip" {
  description = "Public IP address of the Docker VM"
  value       = module.compute.docker_public_ip
}

output "jenkins_vm_ip" {
  description = "Public IP address of the Jenkins VM"
  value       = module.compute.jenkins_public_ip
}

output "workload_identity_client_id" {
  description = "Client ID of the Azure AD application used for AKS Workload Identity"
  value       = var.workload_identity_client_id
}