<#
.SYNOPSIS
    Full validation script for AKS OIDC + Workload Identity + RBAC + CSI pipeline

    Validates:
      - AKS OIDC issuer
      - Workload Identity ServiceAccount
      - Federated Credential
      - UAMI RBAC on Key Vault
      - OIDC token projection in Pod
      - CSI mounts & Key Vault secret fetch
#>

Write-Host "=== VERIFYING AKS OIDC WORKLOAD IDENTITY ===" -ForegroundColor Cyan

# ----------------------------
#  CONFIG
# ----------------------------
$Namespace = "default"
$ServiceAccount = "myapp-sa"
$Deployment = "myapp"

# ----------------------------
# 1. Check AKS Context
# ----------------------------
Write-Host "`n[1/10] Checking current AKS cluster..." -ForegroundColor Yellow
$ctx = kubectl config current-context

if (-not $ctx) {
    Write-Host "ERROR: No AKS context found. Run: az aks get-credentials ..." -ForegroundColor Red
    exit 1
}
Write-Host "Connected to AKS context: $ctx" -ForegroundColor Green

# ----------------------------
# 2. Check OIDC issuer exists
# ----------------------------
Write-Host "`n[2/10] Checking AKS OIDC issuer..." -ForegroundColor Yellow
$oidc = az aks show --query "oidcIssuerProfile.issuerUrl" -o tsv

if (-not $oidc) {
    Write-Host "ERROR: AKS OIDC issuer NOT enabled." -ForegroundColor Red
    exit 1
}
Write-Host "AKS OIDC issuer: $oidc" -ForegroundColor Green

# ----------------------------
# 3. Check ServiceAccount exists
# ----------------------------
Write-Host "`n[3/10] Checking ServiceAccount..." -ForegroundColor Yellow
$sa = kubectl get sa $ServiceAccount -n $Namespace --ignore-not-found

if (-not $sa) {
    Write-Host "ERROR: ServiceAccount '$ServiceAccount' not found in namespace '$Namespace'." -ForegroundColor Red
    exit 1
}
Write-Host "ServiceAccount found: $ServiceAccount" -ForegroundColor Green

# ----------------------------
# 4. Check SA annotation for Workload Identity
# ----------------------------
Write-Host "`n[4/10] Checking SA annotation for Workload Identity..." -ForegroundColor Yellow
$saClientId = kubectl get sa $ServiceAccount -n $Namespace -o jsonpath='{.metadata.annotations.azure\.workload\.identity/client-id}'

if (-not $saClientId) {
    Write-Host "ERROR: ServiceAccount is missing azure.workload.identity/client-id annotation" -ForegroundColor Red
    exit 1
}

Write-Host "ServiceAccount is linked to UAMI Client ID: $saClientId" -ForegroundColor Green

# ----------------------------
# 5. Check Federated Credential exists
# ----------------------------
Write-Host "`n[5/10] Checking Federated Credential..." -ForegroundColor Yellow

$fic = az identity federated-credential list --query "[?contains(subject, '$ServiceAccount')]" -o tsv

if (-not $fic) {
    Write-Host "ERROR: No Federated Credential found for ServiceAccount '$ServiceAccount'." -ForegroundColor Red
    exit 1
}
Write-Host "Federated Credential found for ServiceAccount" -ForegroundColor Green

# ----------------------------
# 6. Check UAMI RBAC on Key Vault
# ----------------------------
Write-Host "`n[6/10] Checking UAMI RBAC on Key Vault..." -ForegroundColor Yellow

$uamiObjId = az identity list --query "[?clientId=='$saClientId'].principalId" -o tsv

if (-not $uamiObjId) {
    Write-Host "ERROR: Unable to find UAMI by clientId: $saClientId" -ForegroundColor Red
    exit 1
}

$kvAssignments = az role assignment list --assignee $uamiObjId --query "[?contains(roleDefinitionName, 'Key Vault')]" -o tsv

if (-not $kvAssignments) {
    Write-Host "ERROR: UAMI does NOT have 'Key Vault Secrets User' RBAC role." -ForegroundColor Red
    exit 1
}

Write-Host "UAMI has correct Key Vault RBAC permissions" -ForegroundColor Green

# ----------------------------
# 7. Check Pod is running
# ----------------------------
Write-Host "`n[7/10] Checking running Pod..." -ForegroundColor Yellow
$pod = kubectl get pod -l app=$Deployment -n $Namespace -o jsonpath='{.items[0].metadata.name}'

if (-not $pod) {
    Write-Host "ERROR: No pod found for deployment '$Deployment'." -ForegroundColor Red
    exit 1
}
Write-Host "Pod found: $pod" -ForegroundColor Green

# ----------------------------
# 8. Check OIDC token projection
# ----------------------------
Write-Host "`n[8/10] Checking OIDC token projection..." -ForegroundColor Yellow

$tokenFile = kubectl exec -n $Namespace $pod -- ls /var/run/secrets/azure/tokens 2>$null

if (-not $tokenFile) {
    Write-Host "ERROR: OIDC token was NOT projected into the pod." -ForegroundColor Red
    exit 1
}

Write-Host "OIDC token projected into pod: $tokenFile" -ForegroundColor Green

# ----------------------------
# 9. Check CSI secret mount
# ----------------------------
Write-Host "`n[9/10] Checking CSI mounted secrets..." -ForegroundColor Yellow

$mount = kubectl exec -n $Namespace $pod -- ls /mnt/secrets 2>$null

if (-not $mount) {
    Write-Host "ERROR: CSI mount is empty — secrets not accessible." -ForegroundColor Red
    exit 1
}

Write-Host "CSI mount contains secrets:" -ForegroundColor Green
Write-Host $mount

# ----------------------------
# 10. Final Verdict
# ----------------------------
Write-Host "`nALL CHECKS PASSED — OIDC Workload Identity + CSI + RBAC are FUNCTIONAL" -ForegroundColor Green