pipeline {
  agent any

  environment {
    ACR_NAME    = "starterkitacr"
    IMAGE_NAME  = "myapp"
    AKS_RG      = "sk-dev2-rg"
    AKS_NAME    = "sk-dev2-aks"
    HELM_CHART  = "helm/myapp"
    NAMESPACE   = "default"
    IMAGE_TAG   = "${BUILD_NUMBER}"
  }

  stages {

    stage('Checkout Code') {
      steps {
        git branch: 'main',
            credentialsId: 'github-credentials',
            url: 'https://github.com/vince-cbaov/Starter-Kit-v4.3.git'
      }
    }

    stage('Azure Login (Build Auth)') {
      steps {
        withCredentials([
          string(credentialsId: 'azure-sp-client-id', variable: 'AZ_CLIENT_ID'),
          string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
          string(credentialsId: 'azure-sp-tenant-id', variable: 'AZ_TENANT_ID')
        ]) {
          sh '''
            set -e
            az login \
              --service-principal \
              -u "$AZ_CLIENT_ID" \
              -p "$AZ_CLIENT_SECRET" \
              --tenant "$AZ_TENANT_ID"
          '''
        }
      }
    }

stage('Build & Push Image (Docker VM)') {
  steps {
    withCredentials([
      string(credentialsId: 'azure-sp-client-id', variable: 'AZ_CLIENT_ID'),
      string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
      string(credentialsId: 'azure-sp-tenant-id', variable: 'AZ_TENANT_ID')
    ]) {
      sh '''
        set -e

        ssh -T -i ~/.ssh/docker_server_key vinadmin@10.10.1.4 << EOF
        set -e

        export AZ_CLIENT_ID="${AZ_CLIENT_ID}"
        export AZ_CLIENT_SECRET="${AZ_CLIENT_SECRET}"
        export AZ_TENANT_ID="${AZ_TENANT_ID}"
        export IMAGE_TAG="${IMAGE_TAG}"

        REPO_DIR="\$HOME/Starter-Kit-v4.3"
        REPO_URL="https://github.com/vince-cbaov/Starter-Kit-v4.3.git"

        echo "Ensuring source code is present..."

        if [ ! -d "\$REPO_DIR/.git" ]; then
          echo "Cloning repository..."
          git clone "\$REPO_URL" "\$REPO_DIR"
        else
          echo "Updating existing repository..."
          cd "\$REPO_DIR"
          git fetch origin
          git reset --hard origin/main
        fi

        cd "\$REPO_DIR"

        echo "Logging into Azure on Docker VM..."
        az login --service-principal \
          -u "\$AZ_CLIENT_ID" \
          -p "\$AZ_CLIENT_SECRET" \
          --tenant "\$AZ_TENANT_ID"

        echo "Logging into ACR..."
        az acr login --name starterkitacr

        echo "Building image with tag: \$IMAGE_TAG"
        docker build -t starterkitacr.azurecr.io/myapp:\$IMAGE_TAG .

        echo "Pushing image..."
        docker push starterkitacr.azurecr.io/myapp:\$IMAGE_TAG
        EOF
      '''
    }
  }
}

    stage('Deploy to AKS') {
      steps {
        withCredentials([
          string(credentialsId: 'azure-sp-client-id', variable: 'AZ_CLIENT_ID'),
          string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
          string(credentialsId: 'azure-sp-tenant-id', variable: 'AZ_TENANT_ID')
        ]) {
          sh '''
            set -e

            echo "Logging into Azure for deployment..."
            az login \
              --service-principal \
              -u "$AZ_CLIENT_ID" \
              -p "$AZ_CLIENT_SECRET" \
              --tenant "$AZ_TENANT_ID"

            echo "Getting AKS credentials..."
            az aks get-credentials \
              --resource-group "$AKS_RG" \
              --name "$AKS_NAME" \
              --overwrite-existing

            echo "Deploying with Helm..."
            helm upgrade --install myapp "$HELM_CHART" \
              --namespace "$NAMESPACE" \
              --create-namespace \
              --set replicaCount=1 \
              --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
              --set image.tag="$IMAGE_TAG" \
              --wait
          '''
        }
      }
    }

  }
}