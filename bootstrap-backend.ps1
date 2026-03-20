# bootstrap-backend.ps1 (no backticks)

$Location  = "northeurope"
$BackendRg = "tfstate-rg"
$BackendSa = ("skstate" + [System.Guid]::NewGuid().ToString("N").Substring(0,12)).ToLower()
$Container = "tfstate"
$BackendTfvars = "envs/dev/backend.tfvars"

# 1) Create RG + Storage + Container
az group create --name $BackendRg --location $Location | Out-Null

az storage account create --name $BackendSa --resource-group $BackendRg --location $Location `
  --sku Standard_LRS --kind StorageV2 | Out-Null

$Key = az storage account keys list --resource-group $BackendRg --account-name $BackendSa `
  --query "[0].value" -o tsv

az storage container create --name $Container --account-name $BackendSa --account-key $Key | Out-Null

# 2) Write backend.tfvars
New-Item -Force -ItemType Directory -Path "envs\dev" | Out-Null
@"
resource_group_name  = "$BackendRg"
storage_account_name = "$BackendSa"
container_name       = "$Container"
key                  = "dev.tfstate"
"@ | Set-Content -Path $BackendTfvars

# 3) Re-init
Remove-Item -Recurse -Force .\.terraform -ErrorAction SilentlyContinue
terraform init -migrate-state -backend-config="$BackendTfvars"