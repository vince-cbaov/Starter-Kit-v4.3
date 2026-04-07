<#
.SYNOPSIS
    Auto-repair script for AKS OIDC + Workload Identity + CSI + RBAC pipeline.

    Repairs:
      - Missing ServiceAccount
      - Missing or incorrect SA annotation
      - Missing Federated Credential
      - Missing RBAC for UAMI on Key Vault
      - Missing CSI secret mount configuration
      - Optionally restarts workload
#>

Write-Host "=== Running AKS OIDC Workload Identity Auto-Repair ===" -ForegroundColor Cyan

# ----------------------------
# CONFIG
# ----------------------------
$Namespace       = "default"
$ServiceAccount  = "myapp-sa"
$Deployment      = "myapp"
$KeyVaultName    = ""   # auto-detected
$Audience        = "api://AzureADTokenExchange"

# ----------------------------
# 1. Detect AKS OIDC Issuer URL
# ----------------------------
Write-Host "`n[1/10] Detecting AKS OIDC Issuer..." -ForegroundColor Yellow
$Issuer = az aks show --query "oidcIssuerProfile.issuerUrl" -o tsv

if (-not $Issuer) {
    Write-Host "ERROR: AKS OIDC issuer not enabled in this cluster." -ForegroundColor Red
    exit 1
}
Write-Host "OIDC issuer: $Issuer" -ForegroundColor Green

# ----------------------------
# 2. Ensure ServiceAccount exists
# ----------------------------
Write-Host "`n[2/10] Ensuring ServiceAccount exists..." -ForegroundColor Yellow
$sa = kubectl get sa $ServiceAccount -n $Namespace --ignore-not-found

if (-not $sa) {
    Write-Host "ServiceAccount missing. Creating it." -ForegroundColor DarkYellow

    kubectl apply -n $Namespace -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $ServiceAccount
  namespace: $Namespace
EOF
}
else {
    Write-Host "ServiceAccount exists." -ForegroundColor Green
}

# ----------------------------
# 3. Retrieve UAMI from SA annotation
# ----------------------------
Write-Host "`n[3/10] Checking ServiceAccount annotation..." -ForegroundColor Yellow
$ClientId = kubectl get sa $ServiceAccount -n $Namespace -o jsonpath='{.metadata.annotations.azure\.workload\.identity/client-id}'

if (-not $ClientId) {
    Write-Host "ServiceAccount missing client-id annotation. Searching for UAMI..." -ForegroundColor DarkYellow

    # Auto-detect the first UAMI in the subscription
    $ClientId = az identity list --query "[0].clientId" -o tsv

    if (-not $ClientId) {
        Write-Host "ERROR: No user assigned managed identity found in subscription." -ForegroundColor Red
        exit 1
    }

    Write-Host "Assigning UAMI to ServiceAccount." -ForegroundColor Yellow

    kubectl annotate sa $ServiceAccount `
        azure.workload.identity/client-id=$ClientId `
        -n $Namespace --overwrite
}
Write-Host "ServiceAccount Workload Identity Client ID: $ClientId" -ForegroundColor Green

# ----------------------------
# 4. Resolve UAMI principal ID
# ----------------------------
Write-Host "`n[4/10] Resolving UAMI principalId..." -ForegroundColor Yellow
$PrincipalId = az identity list --query "[?clientId=='$ClientId'].principalId" -o tsv

if (-not $PrincipalId) {
    Write-Host "ERROR: Could not find UAMI for client-id." -ForegroundColor Red
    exit 1
}
Write-Host "UAMI Principal ID: $PrincipalId" -ForegroundColor Green

# ----------------------------
# 5. Ensure Federated Credential exists
# ----------------------------
Write-Host "`n[5/10] Checking Federated Credential..." -ForegroundColor Yellow
$FID = az identity federated-credential list `
        --query "[?contains(subject, '$ServiceAccount')]" `
        -o tsv

if (-not $FID) {
    Write-Host "Federated Credential missing. Creating it." -ForegroundColor DarkYellow

    $UamiName = az identity list --query "[?clientId=='$ClientId'].name" -o tsv
    $RgName   = az identity list --query "[?clientId=='$ClientId'].resourceGroup" -o tsv

    az identity federated-credential create `
        --name "fic-$ServiceAccount" `
        --identity-name $UamiName `
        --resource-group $RgName `
        --issuer $Issuer `
        --subject "system:serviceaccount:${Namespace}:${ServiceAccount}" `
        --audience $Audience | Out-Null

    Write-Host "Federated Credential created." -ForegroundColor Green
}
else {
    Write-Host "Federated Credential exists." -ForegroundColor Green
}

# ----------------------------
# 6. Detect Key Vault name
# ----------------------------
Write-Host "`n[6/10] Detecting Key Vault..." -ForegroundColor Yellow
$KeyVaultName = az keyvault list --query "[0].name" -o tsv

if (-not $KeyVaultName) {
    Write-Host "ERROR: No Key Vault found in subscription." -ForegroundColor Red
    exit 1
}
Write-Host "Key Vault: $KeyVaultName" -ForegroundColor Green

# ----------------------------
# 7. Ensure RBAC: Key Vault Secrets User
# ----------------------------
Write-Host "`n[7/10] Ensuring RBAC for UAMI on Key Vault..." -ForegroundColor Yellow

$hasRbac = az role assignment list --assignee $PrincipalId `
            --query "[?contains(roleDefinitionName, 'Key Vault Secrets User')]" `
            -o tsv

if (-not $hasRbac) {
    Write-Host "Assigning Key Vault Secrets User role..." -ForegroundColor DarkYellow

    $Scope = az keyvault show -n $KeyVaultName --query id -o tsv

    az role assignment create `
        --assignee $PrincipalId `
        --role "Key Vault Secrets User" `
        --scope $Scope | Out-Null

    Write-Host "RBAC role assigned." -ForegroundColor Green
}
else {
    Write-Host "RBAC is already correct." -ForegroundColor Green
}

# ----------------------------
# 8. Restart Deployment
# ----------------------------
Write-Host "`n[8/10] Restarting deployment to refresh OIDC token..." -ForegroundColor Yellow
kubectl delete deployment $Deployment -n $Namespace --ignore-not-found
Start-Sleep -Seconds 5

kubectl rollout status deployment/$Deployment -n $Namespace --timeout=90s

Write-Host "`nDeployment refreshed." -ForegroundColor Green

# ----------------------------
# 9. Verify CSI volume is attached
# ----------------------------
Write-Host "`n[9/10] Checking CSI mount..." -ForegroundColor Yellow
$Pod = kubectl get pod -l app=$Deployment -n $Namespace -o jsonpath='{.items[0].metadata.name}'

if ($Pod) {
    $Mount = kubectl exec -n $Namespace $Pod -- ls /mnt/secrets 2>$null

    if ($Mount) {
        Write-Host "CSI mount verified." -ForegroundColor Green
    } else {
        Write-Host "WARNING: CSI mount empty. Verify SecretProviderClass configuration." -ForegroundColor Yellow
    }
}
else {
    Write-Host "ERROR: Pod not found for deployment." -ForegroundColor Red
}

# ----------------------------
# 10. Final
# ----------------------------
Write-Host "`nAuto-repair completed." -ForegroundColor Green