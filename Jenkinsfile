pipeline {
  agent any

  parameters {
    string(
      name: 'KV_URL',
      defaultValue: 'https://skdev2kv.vault.azure.net/',
      description: 'Azure Key Vault URL'
    )
    string(
      name: 'sk-dev2-docker-server-ip',
      defaultValue: '10.10.1.4',
      description: 'Docker server private IP'
    )
  }

  sshagent(credentials: ['docker-server-ssh']) {
  sh '''
    ssh -o StrictHostKeyChecking=no vinadmin@10.10.1.4 \
      echo "SSH works from Jenkins"
  '''
}

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

    stage('Scan') {
      steps {
        sh '''
          set -e
          test -f Dockerfile
          test -f helm/myapp/Chart.yaml
          test -f helm/myapp/values.yaml
        '''
      }
    }

    stage('Test') {
      steps {
        sh '''
          set -e
          test -f app/index.html
          grep -qi "<html" app/index.html
        '''
      }
    }

    stage('Verify Parameters') {
      steps {
        echo "Key Vault URL: ${params.KV_URL}"
        echo "Docker Server IP: ${params.DOCKER_SERVER_IP}"
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
            ssh -i /home/vinadmin/.ssh/docker_server_key \
              -o StrictHostKeyChecking=no \
              vinadmin@10.10.1.4 \
              AZ_CLIENT_ID="$AZ_CLIENT_ID" \
              AZ_CLIENT_SECRET="$AZ_CLIENT_SECRET" \
              AZ_TENANT_ID="$AZ_TENANT_ID" \
              ACR_NAME="$ACR_NAME" \
              IMAGE_NAME="$IMAGE_NAME" \
              IMAGE_TAG="$IMAGE_TAG" \
              bash -s < "$WORKSPACE/terraform/scripts/docker-build-push.sh"
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
            az login \
              --service-principal \
              -u "$AZ_CLIENT_ID" \
              -p "$AZ_CLIENT_SECRET" \
              --tenant "$AZ_TENANT_ID"

            az aks get-credentials \
              --resource-group "$AKS_RG" \
              --name "$AKS_NAME" \
              --overwrite-existing

            helm upgrade --install myapp "$HELM_CHART" \
              --namespace default \
              --create-namespace \
              --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
              --set image.tag="$IMAGE_TAG" \
              --wait
          '''
        }
      }
    }
  }
}

