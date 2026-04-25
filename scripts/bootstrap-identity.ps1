param (
    [string]$SubscriptionId = "6fb1fdac-61ae-423c-bbd9-e4a355f030ec",
    [string]$AcrName        = "starterkitacr",
    [string]$KeyVaultName   = "skdev2kv"
)

$ErrorActionPreference = "Stop"

Write-Host "Logging into Azure with Jenkins managed identity"
az login --identity --allow-no-subscriptions | Out-Null
az account set --subscription $SubscriptionId

# Emit values Jenkins actually needs
Write-Output "AZ_SUBSCRIPTION_ID=$SubscriptionId"
Write-Output "ACR_NAME=$AcrName"
Write-Output "KEYVAULT_NAME=$KeyVaultName"
