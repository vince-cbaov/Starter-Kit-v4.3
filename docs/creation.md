# Creation (runtime-input)
1) Export runtime vars and apply Terraform (see scripts/terraform_apply_dev.sh).
2) Enable AKV CSI on AKS and apply SecretProviderClass template.
3) Configure Jenkins credential 'azure-sp' and KV_URL parameter.
4) Run pipeline to build on remote Docker VM, push to ACR, and deploy via Helm.
