#!/usr/bin/env bash
set -euo pipefail

#
# Starter Kit v4.3 – DEV Deployment Script
# Updated to match the exact deploy workflow used manually:
#   terraform fmt
#   terraform init (with backend config)
#   terraform validate
#   terraform plan -var-file
#   terraform apply -var-file
#

# Navigate to the root terraform directory
cd "$(dirname "$0")/../terraform"

echo "======================================================="
echo " Starter Kit v4.3 - Terraform DEV Deployment"
echo " Using envs/dev/terraform.tfvars"
echo "======================================================="

#
# Format and validate
#
terraform fmt -recursive
terraform init -reconfigure -backend-config="envs/dev/backend.tfvars"
terraform validate

#
# Plan
#
terraform plan -var-file="envs/dev/terraform.tfvars"

#
# Apply
#
terraform apply -var-file="envs/dev/terraform.tfvars"

#
# Export outputs to JSON (optional convenience)
#
terraform output -json > envs/dev/tf_outputs_dev.json

echo ""
echo "======================================================="
echo " DEV environment deployed successfully."
echo " Outputs saved to: terraform/envs/dev/tf_outputs_dev.json"
echo "======================================================="