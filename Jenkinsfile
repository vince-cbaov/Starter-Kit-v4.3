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

    stage('Azure Login') {
      steps {
        withCredentials([
          string(credentialsId: 'azure-sp-client-id', variable: 'AZ_CLIENT_ID'),
          string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
          string(credentialsId: 'azure-sp-tenant-id', variable: 'AZ_TENANT_ID')
        ]) {
          sh '''
            az login --service-principal \
              -u $AZ_CLIENT_ID \
              -p $AZ_CLIENT_SECRET \
              --tenant $AZ_TENANT_ID
          '''
        }
      }
    }

  stage('Build & Push Image (Docker Server)') {
    steps {
      withCredentials([
       usernamePassword(
        credentialsId: 'acr-credentials',
        usernameVariable: 'ACR_USER',
        passwordVariable: 'ACR_PASS'
      )
    ]) {
      sh """
        ssh vinadmin@10.10.1.5 '
          docker login starterkitacr.azurecr.io -u ${ACR_USER} -p ${ACR_PASS} &&
          docker build -t starterkitacr.azurecr.io/myapp:${IMAGE_TAG} . &&
          docker push starterkitacr.azurecr.io/myapp:${IMAGE_TAG}
        '
      """
    }
  }
}

    stage('Build Image') {
      steps {
        sh '''
          docker build \
            -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG \
            .
        '''
      }
    }

    stage('Push Image') {
      steps {
        sh '''
          docker push \
            $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG
        '''
      }
    }

    stage('Deploy to AKS') {
      steps {
        sh '''
          az aks get-credentials \
            --resource-group $AKS_RG \
            --name $AKS_NAME \
            --overwrite-existing

          helm upgrade --install myapp $HELM_CHART \
            --namespace $NAMESPACE \
            --set replicaCount=1 \
            --set image.repository=$ACR_NAME.azurecr.io/$IMAGE_NAME \
            --set image.tag=$IMAGE_TAG
        '''
      }
    }

  }
}