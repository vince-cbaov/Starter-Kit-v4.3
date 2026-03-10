pipeline {
  agent any
  environment { IMAGE_NAME = "starterkit" }
  parameters { string(name: 'KV_URL', defaultValue: '', description: 'Azure Key Vault URL, e.g. https://<kvname>.vault.azure.net/')
               string(name: 'DOCKER_SERVER_IP', defaultValue: '', description: 'Docker VM public IP for DOCKER_HOST tcp://<ip>:2375') }
  stages {
    stage('Fetch Secrets from Key Vault') {
      steps {
        script { if (!params.KV_URL?.trim()) { error 'KV_URL parameter not set.' } }
        azureKeyVault(credentialID: 'azure-sp', keyVaultURL: params.KV_URL,
          secrets: [[name: 'acr-sp-app-id', envVariable: 'ACR_USERNAME'],
                    [name: 'acr-sp-secret', envVariable: 'ACR_PASSWORD'],
                    [name: 'acr-name',      envVariable: 'ACR_NAME']])
        sh 'echo "Fetched ACR creds for $ACR_NAME from Key Vault"'
      }
    }
    stage('Checkout') { steps { checkout scm } }
    stage('Build on Docker VM') {
      steps {
        script { if (!params.DOCKER_SERVER_IP?.trim()) { error 'Set DOCKER_SERVER_IP parameter.' } }
        sh 'export DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375 && docker version'
        sh 'export DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375 && docker build -t $ACR_NAME.azurecr.io/$IMAGE_NAME:${GIT_COMMIT} app/'
      }
    }
    stage('ACR Login & Push') {
      steps {
        sh 'echo $ACR_PASSWORD | docker login $ACR_NAME.azurecr.io -u $ACR_USERNAME --password-stdin'
        sh 'export DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375 && docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:${GIT_COMMIT}'
        sh 'export DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375 && docker tag $ACR_NAME.azurecr.io/$IMAGE_NAME:${GIT_COMMIT} $ACR_NAME.azurecr.io/$IMAGE_NAME:latest'
        sh 'export DOCKER_HOST=tcp://${DOCKER_SERVER_IP}:2375 && docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:latest'
      }
    }
    stage('Helm Deploy') {
      steps {
        sh 'helm upgrade --install myapp helm/myapp --namespace starterkit --create-namespace --set image.repository=$ACR_NAME.azurecr.io/$IMAGE_NAME --set image.tag=${GIT_COMMIT}'
      }
    }
    stage('Rollout Status') { steps { sh 'kubectl rollout status deploy/myapp -n starterkit' } }
  }
}
