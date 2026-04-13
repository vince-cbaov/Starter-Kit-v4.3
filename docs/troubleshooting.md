# Troubleshooting
- Docker build connectivity: Jenkins initiates Docker builds over SSH, connecting only to the remote build VM. Ensure:
- SSH access is available from Jenkins to the build VM
- Docker daemon is running locally on the build VM
- Key Vault access: Confirm Jenkins Service Principal has GET and LIST permissions on Key Vault secrets.
- AKS image pulls: Verify AKS managed identity has AcrPull role assigned. If not, fallback to an imagePullSecret defined in helm/values.yaml.
Test