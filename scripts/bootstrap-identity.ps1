param (
    [string]$SubscriptionId = "6fb1fdac-61ae-423c-bbd9-e4a355f030ec",
    [string]$ResourceGroup  = "sk-dev2-rg",
    [string]$AksName        = "sk-dev2-aks",
    [string]$KeyVaultName   = "skdev2kv",
    [string]$AcrName        = "starterkitacr",
    [string]$ServiceAccount = "myapp-sa",
    [string]$Namespace      = "default",
    [string]$ClientId       = "e5f21f47-6236-455a-af6d-79277ee40d36",
    [string]$UamiName       = "sk-dev2-uami"
)

$ErrorActionPreference = "Stop"

az login --identity --allow-no-subscriptions

az account set --subscription $SubscriptionId

# -------------------------
# 1. Get AKS OIDC Issuer
# -------------------------
$OidcIssuer = az aks show `
  --resource-group $ResourceGroup `
  --name $AksName `
  --query "oidcIssuerProfile.issuerUrl" `
  -o tsv

# -------------------------
# 2. Create Federation JSON
# -------------------------
$federationFile = "$PSScriptRoot\myapp-federation.json"

@"
{
  "name": "myapp-sa-federation",
  "issuer": "$OidcIssuer",
  "subject": "system:serviceaccount:${Namespace}:${ServiceAccount}",
  "audiences": ["api://AzureADTokenExchange"]
}
"@ | Out-File -Encoding utf8 $federationFile

# -------------------------
# 3. Create Federated Credential (idempotent)
# -------------------------
$federations = az identity federated-credential list `
  --id $ClientId `
  --query "[?subject=='system:serviceaccount:${Namespace}:${ServiceAccount}']" `
  -o tsv

if (-not $federations) {
    az identity federated-credential create `
        --id $ClientId `
        --parameters $federationFile
}

# -------------------------
# 4. Assign Key Vault Role
# -------------------------
$kvScope = az keyvault show `
  --name $KeyVaultName `
  --resource-group $ResourceGroup `
  --query id -o tsv

az role assignment create `
  --assignee $ClientId `
  --role "Key Vault Secrets User" `
  --scope $kvScope `
  2>$null

# -------------------------
# 5. Assign ACR Roles
# -------------------------
$acrId = az acr show `
  --name $AcrName `
  --resource-group $ResourceGroup `
  --query id -o tsv

az role assignment create `
  --assignee $ClientId `
  --role AcrPush `
  --scope $acrId `
  2>$null

# -------------------------
# 6. Attach UAMI to VMs (safe to re-run)
# -------------------------
az vm identity assign `
  --name sk-dev2-docker `
  --resource-group $ResourceGroup `
  --identities $UamiName `
  2>$null

az vm identity assign `
  --name sk-dev2-jenkins `
  --resource-group $ResourceGroup `
  --identities $UamiName `
  2>$null

# -------------------------
# 7. Emit Outputs for Jenkins
# -------------------------
Write-Output "AZURE_CLIENT_ID=$ClientId"
Write-Output "AKS_OIDC_ISSUER=$OidcIssuer"
Write-Output "KEYVAULT_NAME=$KeyVaultName"
Write-Output "ACR_NAME=$AcrName"