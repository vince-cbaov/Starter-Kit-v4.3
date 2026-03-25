param(
    [string]$ImageTag = "v1",    # Override when deploying v2 or Jenkins build number
    [switch]$EnableCSI            # Enable if you want to configure Key Vault CSI in one shot
)

Write-Host "========================================"
Write-Host " Starter Kit v4.3 - Full AKS Deployment "
Write-Host " PowerShell Automated Script"
Write-Host "========================================`n"

# ------------------------------------------
# 1. Load Terraform Outputs
# ------------------------------------------
Write-Host "Fetching Terraform outputs..."

$TFDir = "terraform"
Push-Location $TFDir

$RG_NAME     = terraform output -raw rg_name
$AKS_NAME    = terraform output -raw aks_name
$ACR_SERVER  = terraform output -raw acr_login_server
$KV_NAME     = terraform output -raw kv_name
$TENANT_ID   = terraform output -raw tenant_id

Pop-Location

Write-Host "`nTerraform Info:"
Write-Host " Resource Group : $RG_NAME"
Write-Host " AKS Cluster    : $AKS_NAME"
Write-Host " ACR Server     : $ACR_SERVER"
Write-Host " Key Vault      : $KV_NAME"
Write-Host " Tenant ID      : $TENANT_ID"
Write-Host " Image Tag      : $ImageTag"
Write-Host "========================================`n"


# ------------------------------------------
# 2. Connect kubectl to AKS
# ------------------------------------------
Write-Host "Connecting to AKS..."

az aks get-credentials `
  --resource-group $RG_NAME `
  --name $AKS_NAME `
  --overwrite-existing

kubectl get nodes


# ------------------------------------------
# 3. Build and Push Docker Image
# ------------------------------------------
Write-Host "`nBuilding and pushing Docker image..."

$ImagePath = "$ACR_SERVER/myapp:$ImageTag"

docker build -t $ImagePath .
docker push $ImagePath


# ------------------------------------------
# 4. Helm Deploy
# ------------------------------------------
Write-Host "`nDeploying with Helm..."

helm upgrade --install myapp ./helm/myapp `
  --set image.repository="$ACR_SERVER/myapp" `
  --set image.tag="$ImageTag"

kubectl get svc


# ------------------------------------------
# 5. Optional: Enable Key Vault CSI
# ------------------------------------------
if ($EnableCSI) {

    Write-Host "`nEnabling Key Vault CSI Driver..."

    az aks enable-addons `
      --addons azure-keyvault-secrets-provider `
      --resource-group $RG_NAME `
      --name $AKS_NAME

    # Write the SecretProviderClass
    $spcPath = "k8s\csi\secretproviderclass.yaml"

@"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: akv-secrets
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    keyvaultName: "$KV_NAME"
    tenantId: "$TENANT_ID"
    objects: |
      array:
        - |
          objectName: acr-sp-app-id
          objectType: secret
        - |
          objectName: acr-sp-secret
          objectType: secret
        - |
          objectName: tenant-id
          objectType: secret
"@ | Set-Content $spcPath -Encoding UTF8

    Write-Host "`nApplying SecretProviderClass..."
    kubectl apply -f $spcPath

    Write-Host "Re-deploying Helm chart to mount secrets..."
    helm upgrade --install myapp ./helm/myapp

    Write-Host "`nVerifying secret mount..."
    $POD = kubectl get pod -l app=myapp -o jsonpath='{.items[0].metadata.name}'
    kubectl exec -it $POD -- ls /mnt/secrets
}


# ------------------------------------------
# Deployment Complete
# ------------------------------------------
Write-Host "`n========================================"
Write-Host " Deployment Complete "
Write-Host " Check your AKS service external IP:"
kubectl get svc myapp
Write-Host "========================================"