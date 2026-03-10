# Troubleshooting
- Docker remote API: ensure port 2375 open from Jenkins IP only.
- Key Vault access: Jenkins SP must have GET/LIST secret permissions.
- AKS pull: AcrPull role assignment present; otherwise use imagePullSecret.
