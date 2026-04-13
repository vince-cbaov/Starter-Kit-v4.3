# Outputs
- Terraform outputs generated from terraform_apply_dev.sh:
- kv_name, acr_name, acr_login_server, aks_name
- Jenkins pipeline logs confirm: 
- Key Vault secret fetch (via CSI Driver)
- Docker image build and push to ACR
- Helm deploy to AKS using outputs and chart templates
- Kubernetes rollout progression and revision history

