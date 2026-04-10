#!/usr/bin/env bash
set -e

echo "Ensuring source code is present..."
mkdir -p /var/tmp/build
cd /var/tmp/build

if [ ! -d Starter-Kit-v4.3/.git ]; then
  git clone https://github.com/vince-cbaov/Starter-Kit-v4.3.git
else
  cd Starter-Kit-v4.3
  git fetch origin
  git reset --hard origin/main
fi

cd Starter-Kit-v4.3

echo "Logging into Azure..."
az login \
  --service-principal \
  -u "$AZ_CLIENT_ID" \
  -p "$AZ_CLIENT_SECRET" \
  --tenant "$AZ_TENANT_ID" \
  --output none

echo "Logging into ACR..."
TOKEN=$(az acr login \
  --name "$ACR_NAME" \
  --expose-token \
  --output tsv \
  --query accessToken)

test -n "$TOKEN"

echo "$TOKEN" | docker login "$ACR_NAME.azurecr.io" \
  --username 00000000-0000-0000-0000-000000000000 \
  --password-stdin

docker build -t "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG" .
docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG"