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

    /* ============================
       SCAN STAGE (QUALITY GATE)
       ============================ */

    stage('Scan') {
      steps {
        sh '''
          set -e
          echo "Running basic security and quality scans..."

          echo "Checking Dockerfile exists..."
          test -f Dockerfile

          echo "Checking Helm chart structure..."
          test -d helm/myapp
          test -f helm/myapp/Chart.yaml
          test -f helm/myapp/values.yaml

          echo "Scan stage complete."
        '''
      }
    }

    /* ============================
       TEST STAGE (CORRECTNESS GATE)
       ============================ */

    stage('Test') {
      steps {
        sh '''
          set -e
          echo "Running application tests..."

          echo "Validating app files..."
          test -f app/index.html

          echo "Basic HTML sanity check..."
          grep -qi "<html" app/index.html

          echo "Test stage complete."
        '''
      }
    }

    /* ============================
       BUILD AUTH (AZURE LOGIN)
       ============================ */

    stage('Azure Login (Build Auth)') {
      steps {
        withCredentials([
          string(credentialsId: 'azure-sp-client-id', variable: 'AZ_CLIENT_ID'),
          string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
          string(credentialsId: 'azure-sp-tenant-id', variable: 'AZ_TENANT_ID')
        ]) {
          sh '''
            set -e
            echo "Logging into Azure (Jenkins VM)..."
            az login \
              --service-principal \
              -u "$AZ_CLIENT_ID" \
              -p "$AZ_CLIENT_SECRET" \
              --tenant "$AZ_TENANT_ID"
          '''
        }
      }
    }

    /* ============================
       BUILD & PUSH (DOCKER VM)
       ============================ */
    
    stage('Build & Push Image (Docker VM)') {
      steps {
        withCredentials([
          string(credentialsId: 'azure-sp-client-id', variable: 'AZ_CLIENT_ID'),
          string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
          string(credentialsId: 'azure-sp-tenant-id', variable: 'AZ_TENANT_ID')
        ]) {
          sh '''
            set -e

            ssh -T -i ~/.ssh/docker_server_key vinadmin@10.10.1.5 << EOF
              set -e

              export AZ_CLIENT_ID="${AZ_CLIENT_ID}"
              export AZ_CLIENT_SECRET="${AZ_CLIENT_SECRET}"
              export AZ_TENANT_ID="${AZ_TENANT_ID}"
              export IMAGE_TAG="${IMAGE_TAG}"
              export ACR_NAME="${ACR_NAME}"
              export IMAGE_NAME="${IMAGE_NAME}"

              echo "Ensuring source code is present..."

              if [ ! -d "/var/tmp/build/Starter-Kit-v4.3/.git" ]; then
                git clone https://github.com/vince-cbaov/Starter-Kit-v4.3.git /var/tmp/build/Starter-Kit-v4.3
              else
                cd /var/tmp/build/Starter-Kit-v4.3
                git fetch origin
                git reset --hard origin/main
              fi

              cd /var/tmp/build/Starter-Kit-v4.3

              echo "Logging into Azure (Docker VM)..."
              az login --service-principal \
                -u "$AZ_CLIENT_ID" \
                -p "$AZ_CLIENT_SECRET" \
                --tenant "$AZ_TENANT_ID"

              echo "Logging into ACR using token..."
              TOKEN=$(az acr login \
              --name "$ACR_NAME" \
              --expose-token \
              --output tsv \
              --query accessToken)

              docker login ${ACR_NAME}.azurecr.io \
              --username 00000000-0000-0000-0000-000000000000 \
              --password "$TOKEN"

              echo "Building Docker image ${IMAGE_TAG}..."
              sudo docker build -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .

              echo "Pushing Docker image..."
              sudo docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}

            EOF
          '''
        }
      }
    }

    /* ============================
       DEPLOY (HELM → AKS)
       ============================ */

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

            echo "Fetching AKS credentials..."
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
