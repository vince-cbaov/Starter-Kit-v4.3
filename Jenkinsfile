pipeline {
  agent any

  options {
    // Fail fast if any command errors inside a stage using set -e
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    IMAGE_NAME = "starterkit"
  }

  parameters {
    string(name: 'KV_URL', defaultValue: '', description: 'Azure Key Vault URL, e.g. https://<kvname>.vault.azure.net/')
    string(name: 'DOCKER_SERVER_IP', defaultValue: '', description: 'Docker VM public IP for DOCKER_HOST tcp://<ip>:2375')
  }

  stages {
    stage('Fetch Secrets from Key Vault') {
      steps {
        script {
          if (!params.KV_URL?.trim()) { error 'KV_URL parameter not set.' }
        }
        // Ensure you have the Azure Key Vault plugin configured and a Jenkins credential with ID 'azure-sp'
        azureKeyVault(
          credentialId: 'azure-sp',              // << note: credentialId (lowercase 'd')
          keyVaultURL: params.KV_URL,
          secrets: [
            [name: 'acr-sp-app-id', envVariable: 'ACR_USERNAME'],
            [name: 'acr-sp-secret', envVariable: 'ACR_PASSWORD'],
            [name: 'acr-name',      envVariable: 'ACR_NAME']
          ]
        )
        sh 'echo "Fetched ACR creds for $ACR_NAME from Key Vault"'
      }
    }

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build on Docker VM') {
      steps {
        script {
          if (!params.DOCKER_SERVER_IP?.trim()) { error 'Set DOCKER_SERVER_IP parameter.' }
        }
        withEnv(["DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375"]) {
          sh '''
            set -e
            docker version
            docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:${GIT_COMMIT} app/
          '''
        }
      }
    }

    stage('ACR Login & Push') {
      steps {
        withEnv(["DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375"]) {
          sh '''
            set -e
            echo "$ACR_PASSWORD" | docker login "$ACR_NAME.azurecr.io" -u "$ACR_USERNAME" --password-stdin
            docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:${GIT_COMMIT}"
            docker tag  "$ACR_NAME.azurecr.io/$IMAGE_NAME:${GIT_COMMIT}" "$ACR_NAME.azurecr.io/$IMAGE_NAME:latest"
            docker push "$ACR_NAME.azurecr.io/$IMAGE_NAME:latest"
          '''
        }
      }
    }

    stage('Helm Deploy') {
      steps {
        // Requires kubectl/helm and a kubeconfig on the agent
        sh '''
          set -e
          helm upgrade --install myapp helm/myapp \
            --namespace starterkit --create-namespace \
            --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
            --set image.tag="${GIT_COMMIT}"
        '''
      }
    }

    stage('Rollout Status') {
      steps {
        sh 'kubectl rollout status deploy/myapp -n starterkit'
      }
    }
  }
}