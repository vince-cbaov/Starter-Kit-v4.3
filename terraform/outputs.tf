output "kv_name" {
  value = module.kv.kv_name
}

output "kv_uri" {
  value = module.kv.kv_uri
}

output "rg_name" {
  value = module.rg.name
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
