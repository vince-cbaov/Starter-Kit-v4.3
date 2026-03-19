#!/usr/bin/env bash
set -euo pipefail

# === Config (adjust if you like) ===
LOCATION="northeurope"              # aligns with your variables.tf default
BACKEND_RG="tfstate-rg"             # dedicated RG for state
BACKEND_SA="skstate$RANDOM$RANDOM"  # must be globally unique, lowercase
CONTAINER="tfstate"
BACKEND_FILE="envs/dev/backend.tfvars"

# === Prereqs ===
command -v az >/dev/null 2>&1 || { echo >&2 "az CLI not found."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo >&2 "terraform not found."; exit 1; }

# (Optional) ensure subscription:
# az account set --subscription "<your-subscription-id-or-name>"

echo "Creating backend Resource Group: $BACKEND_RG ($LOCATION)"
az group create --name "$BACKEND_RG" --location "$LOCATION" >/dev/null

echo "Creating backend Storage Account: $BACKEND_SA"
az storage account create \
  --name "$BACKEND_SA" \
  --resource-group "$BACKEND_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 >/dev/null

echo "Fetching storage account key..."
STORAGE_KEY="$(az storage account keys list \
  --resource-group "$BACKEND_RG" \
  --account-name "$BACKEND_SA" \
  --query '[0].value' -o tsv)"

echo "Creating blob container: $CONTAINER"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$BACKEND_SA" \
  --account-key "$STORAGE_KEY" >/dev/null

echo "Writing $BACKEND_FILE"
mkdir -p "$(dirname "$BACKEND_FILE")"
cat > "$BACKEND_FILE" <<EOF
resource_group_name  = "$BACKEND_RG"
storage_account_name = "$BACKEND_SA"
container_name       = "$CONTAINER"
key                  = "dev.tfstate"
EOF

echo "Re-initialising Terraform backend and migrating any local state..."
rm -rf .terraform
terraform init -migrate-state -backend-config="$BACKEND_FILE"

echo "Backend ready."
echo "  RG:        $BACKEND_RG"
echo "  Storage:   $BACKEND_SA"
echo "  Container: $CONTAINER"
echo "  Config:    $BACKEND_FILE"
