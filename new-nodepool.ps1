# -------------------------------
# VARIABLES - UPDATE IF NECESSARY
# -------------------------------
$RG         = "sk-dev-rg"
$AKS        = "sk-dev-aks"
$OLDPOOL    = "nodepool1"
$NEWPOOL    = "nodepool2"


# -------------------------------
# 1. CREATE NEW NODEPOOL
# -------------------------------
Write-Host "Creating new nodepool: $NEWPOOL ..." -ForegroundColor Cyan

az aks nodepool add `
    --resource-group $RG `
    --cluster-name $AKS `
    --name $NEWPOOL `
    --node-count 1 `
    --enable-cluster-autoscaler `
    --min-count 1 `
    --max-count 3 `
    --mode User `
    --node-vm-size Standard_DS2_v2 `
    --os-type Linux `


Write-Host "New nodepool created." -ForegroundColor Green


# -------------------------------
# 2. WAIT FOR NEW NODE TO BECOME READY
# -------------------------------
Write-Host "Waiting for new node to become Ready..." -ForegroundColor Cyan

do {
    Start-Sleep -Seconds 5
    $ready = kubectl get nodes -o json | ConvertFrom-Json |
             Select-Object -ExpandProperty items |
             Where-Object {
                $_.metadata.labels."agentpool" -eq $NEWPOOL -and
                ($_.status.conditions | Where-Object { $_.type -eq "Ready" }).status -eq "True"
             }
} until ($ready)

Write-Host "New node is Ready." -ForegroundColor Green


# -------------------------------
# 3. WAIT FOR CSI DRIVER TO LAND ON NEW NODE
# -------------------------------
Write-Host "Waiting for CSI driver pods to appear on new node..." -ForegroundColor Cyan

$newNodeName = $ready.metadata.name

do {
    Start-Sleep -Seconds 5
    $csi = kubectl get pods -n kube-system -o wide |
           Select-String $newNodeName | Select-String "secrets-store"
} until ($csi)

Write-Host "CSI driver running on new node." -ForegroundColor Green


# -------------------------------
# 4. CORDON OLD NODEPOOL NODES
# -------------------------------
Write-Host "🧹 Cordoning all nodes in old nodepool $OLDPOOL ..." -ForegroundColor Cyan

$oldNodes = kubectl get nodes -o json | ConvertFrom-Json |
            Select-Object -ExpandProperty items |
            Where-Object { $_.metadata.labels."agentpool" -eq $OLDPOOL }

foreach ($node in $oldNodes) {
    $nodeName = $node.metadata.name
    Write-Host " - Cordoning $nodeName ..."
    kubectl cordon $nodeName
}

Write-Host "All old nodes cordoned." -ForegroundColor Green


# -------------------------------
# 5. DRAIN OLD NODEPOOL NODES
# -------------------------------
Write-Host "Draining workloads from old nodes..." -ForegroundColor Cyan

foreach ($node in $oldNodes) {
    $nodeName = $node.metadata.name
    Write-Host " - Draining $nodeName ..."
    kubectl drain $nodeName --ignore-daemonsets --delete-emptydir-data --force
}

Write-Host "All workloads drained from old nodepool." -ForegroundColor Green


# -------------------------------
# 6. DELETE OLD NODEPOOL
# -------------------------------
Write-Host "Deleting old nodepool $OLDPOOL ..." -ForegroundColor Cyan

az aks nodepool delete `
    --resource-group $RG `
    --cluster-name $AKS `
    --name $OLDPOOL

Write-Host "Old nodepool successfully deleted." -ForegroundColor Yellow


# -------------------------------
# 7. RESTART YOUR APP
# -------------------------------
Write-Host "Restarting deployment myapp ..." -ForegroundColor Cyan

kubectl rollout restart deployment/myapp

Write-Host "Waiting for rollout..."
kubectl rollout status deployment/myapp

Write-Host "myapp successfully rolled out onto the NEW nodepool!" -ForegroundColor Green