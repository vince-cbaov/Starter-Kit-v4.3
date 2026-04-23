param (
    [string]$SubscriptionId = "6fb1fdac-61ae-423c-bbd9-e4a355f030ec",
    [string]$ResourceGroup  = "sk-dev2-rg",
    [string]$AksName        = "sk-dev2-aks",
    [string]$KeyVaultName   = "skdev2kv",
    [string]$AcrName        = "starterkitacr",
    [string]$ServiceAccount = "myapp-sa",
    [string]$Namespace      = "default",
    [string]$UamiName       = "sk-dev2-uami"
)

$ErrorActionPreference = "Stop"

Write-Host "Logging into Azure with managed identity"
az login --identity --allow-no-subscriptions | Out-Null
az account set --subscription $SubscriptionId

# -------------------------
# 1. Resolve User Assigned Managed Identity
# -------------------------
$uami = az identity show `
  --name $UamiName `
  --resource-group $ResourceGroup `
  -o json | ConvertFrom-Json

$UamiPrincipalId = $uami.principalId
$UamiClientId   = $uami.clientId

# -------------------------
# 2. Get AKS OIDC Issuer
# -------------------------
$OidcIssuer = az aks show `
  --resource-group $ResourceGroup `
  --name $AksName `
  --query "oidcIssuerProfile.issuerUrl" `
  -o tsv

# -------------------------
# 3. Federated Identity Credential (idempotent)
# -------------------------
$existingFic = az identity federated-credential list `
  --identity-name $UamiName `
  --resource-group $ResourceGroup `
  --query "[?subject=='system:serviceaccount:${Namespace}:${ServiceAccount}'].name" `
  -o tsv

if (-not $existingFic) {
    Write-Host "Creating federated identity credential for Workload Identity"

    az identity federated-credential create `
      --name "myapp-fic" `
      --identity-name $UamiName `
      --resource-group $ResourceGroup `
      --issuer $OidcIssuer `
      --subject "system:serviceaccount:${Namespace}:${ServiceAccount}" `
      --audiences "api://AzureADTokenExchange"
}

# -------------------------
# 4. Key Vault access for workload identity
# -------------------------
$kvId = az keyvault show `
  --name $KeyVaultName `
  --resource-group $ResourceGroup `
  --query id -o tsv

az role assignment create `
  --assignee-object-id $UamiPrincipalId `
  --assignee-principal-type ServicePrincipal `
  --role "Key Vault Secrets User" `
  --scope $kvId `
  2>$null

# -------------------------
# 5. ACR RBAC (build + runtime)
# -------------------------
$acrId = az acr show `
  --name $AcrName `
  --resource-group $ResourceGroup `
  --query id -o tsv

# Build VM / CI push
az role assignment create `
  --assignee-object-id $UamiPrincipalId `
  --assignee-principal-type ServicePrincipal `
  --role AcrPush `
  --scope $acrId `
  2>$null

# AKS kubelet pull
$kubeletObjectId = az aks show `
  --resource-group $ResourceGroup `
  --name $AksName `
  --query identityProfile.kubeletidentity.objectId `
  -o tsv

az role assignment create `
  --assignee-object-id $kubeletObjectId `
  --assignee-principal-type ServicePrincipal `
  --role AcrPull `
  --scope $acrId `
  2>$null

# -------------------------
# 6. Attach UAMI to Docker build VM only
# -------------------------
az vm identity assign `
  --name sk-dev2-docker `
  --resource-group $ResourceGroup `
  --identities $UamiName `
  2>$null

# -------------------------
# 7. Emit outputs for Jenkins
# -------------------------
Write-Output "AZURE_CLIENT_ID=$UamiClientId"
Write-Output "AKS_OIDC_ISSUER=$OidcIssuer"
Write-Output "KEYVAULT_NAME=$KeyVaultName"
Write-Output "ACR_NAME=$AcrName"
Write-Output "AZ_SUBSCRIPTION_ID=$SubscriptionId"