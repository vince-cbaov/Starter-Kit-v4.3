output "kv_name" {
  value = module.kv.kv_name
}

output "kv_uri" {
  value = module.kv.kv_uri
}

output "rg_name" {
  value = module.rg.name
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

output "rg_location" {
  value = module.rg.location
}

output "acr_name" {
  value = module.acr.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "aks_name" {
  value = module.aks.name
}

output "docker_vm_ip" {
  value = module.compute.docker_public_ip
}

output "jenkins_vm_ip" {
  value = module.compute.jenkins_public_ip
}

output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}
