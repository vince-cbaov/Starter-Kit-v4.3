# Creation (runtime-input)

1) Export runtime environment variables and run scripts/terraform_apply_dev.sh, provisioning Azure infrastructure via Terraform under terraform/ (including modules for AKS, ACR, Key Vault, networking).
2) From Terraform outputs—kv_name, acr_name, acr_login_server, aks_name—capture values for downstream use.
3) Within the terraform/aks module, enable Key Vault CSI Driver and AKS Workload Identity, then apply the SecretProviderClass manifest located under helm/your-app/templates/.
4) In Jenkins, configure:
5) Credential: azure-sp (Service Principal for Azure access)
6) Parameter: KV_URL, pointing to the provisioned Key Vault’s URL.
7) Execute the Jenkins pipeline in Jenkinsfile, which orchestrates:
8) SSH-driven Docker build on the remote Docker VM (no TCP ports exposed)
9) Docker image build and tag
10) Push to Azure Container Registry (from acr_name)
11) Deployment to AKS using Helm charts under helm/ (monitored via rollout strategy)
