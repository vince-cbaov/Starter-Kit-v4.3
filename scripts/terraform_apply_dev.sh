#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../terraform/envs/dev"
: "${SP_APP_ID:?Set SP_APP_ID}"
: "${SP_SECRET:?Set SP_SECRET}"
: "${TENANT_ID:?Set TENANT_ID}"
: "${ACR_NAME:=starterkitacr}"
: "${SSH_PUBLIC_KEY:=}"
terraform init -backend-config=backend.tfvars
terraform apply -auto-approve   -var="location=northeurope"   -var="name_prefix=sk-dev"   -var="admin_username=vinadmin"   -var="acr_name=$ACR_NAME"   -var="sp_app_id=$SP_APP_ID"   -var="sp_secret=$SP_SECRET"   -var="tenant_id=$TENANT_ID"   -var="ssh_public_key=$SSH_PUBLIC_KEY"   -var="create_vms=true"   -var="enable_docker_vm=true"
terraform output -json > ../tf_outputs_dev.json
