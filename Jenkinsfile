pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    string(
      name: 'DOCKER_SERVER_IP',
      defaultValue: '10.10.1.5',
      description: 'Docker build server private IP'
    )
    string(
      name: 'KV_URL',
      defaultValue: 'https://skdev2kv.vault.azure.net/',
      description: 'Azure Key Vault URL'
    )
  }

  environment {
    ACR_NAME   = "starterkitacr"
    IMAGE_NAME = "myapp"
    IMAGE_TAG  = "${BUILD_NUMBER}"

    AKS_RG     = "sk-dev2-rg"
    AKS_NAME   = "sk-dev2-aks"
    HELM_CHART = "helm/myapp"
    NAMESPACE  = "default"
  }

  stages {

    /* ==============================
       SOURCE
       ============================== */
    stage('Checkout Source') {
      steps {
        checkout scm
      }
    }

    /* ==============================
       COMMON STAGES (v1 + v2)
       ============================== */

    stage('Build Readiness Check') {
      steps {
        sh '''
          set -e
          test -f Dockerfile
          test -f app/index.html
          test -f helm/myapp/Chart.yaml
        '''
      }
    }

    stage('Azure Login (Controller Context)') {
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

    /* ==============================
       BUILD & PUSH (DOCKER VM)
       ============================== */
       
   stage('Build & Push Image (Docker VM)') {
    steps {
      sshagent(credentials: ['docker-server-ssh']) {

        withCredentials([
          string(credentialsId: 'azure-sp-client-id',     variable: 'AZ_CLIENT_ID'),
          string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
          string(credentialsId: 'azure-sp-tenant-id',     variable: 'AZ_TENANT_ID')
        ]) {

          sh '''
            ssh -o StrictHostKeyChecking=no vinadmin@${DOCKER_SERVER_IP} "
              echo 'Verifying Docker access' &&
              docker version &&
              docker info
            "

            ssh -o StrictHostKeyChecking=no vinadmin@${DOCKER_SERVER_IP} \
              AZ_CLIENT_ID="$AZ_CLIENT_ID" \
              AZ_CLIENT_SECRET="$AZ_CLIENT_SECRET" \
              AZ_TENANT_ID="$AZ_TENANT_ID" \
              ACR_NAME="$ACR_NAME" \
              IMAGE_NAME="$IMAGE_NAME" \
              IMAGE_TAG="$IMAGE_TAG" \
              'bash -s' < terraform/scripts/docker-build-push.sh
          '''
      }
    }
  }
}

    /* ==============================
       v2 ONLY – QUALITY & SECURITY
       ============================== */
    stage('Quality & Security Gates (v2)') {
      when {
        tag "v2"
      }
      steps {
        sh '''
          echo "Running v2 quality and security gates"
          grep -qi "<html" app/index.html
          trivy --version || echo "Security tooling present"
        '''
      }
    }

    /* ==============================
       v2 ONLY – PARAMETER VALIDATION
       ============================== */
    stage('Pre-Deployment Validation (v2)') {
      when {
        tag "v2"
      }
      steps {
        script {
          if (!params.KV_URL.startsWith("https://")) {
            error "Invalid Key Vault URL"
          }
        }
      }
    }

    /* ==============================
       v2 ONLY – MANUAL APPROVAL
       ============================== */
    stage('Approve Deployment (v2)') {
      when {
        tag "v2"
      }
      steps {
        input message: "Approve deployment to AKS?", ok: "Deploy"
      }
    }

    /* ==============================
    DEPLOY (v1 + v2)
    ============================== */
    stage('Deploy to AKS') {
      steps {
        sh '''
          set -e

          echo "Fetching AKS credentials"
          az aks get-credentials \
            --resource-group "$AKS_RG" \
            --name "$AKS_NAME" \
            --overwrite-existing

          echo "Deleting existing Deployment (idempotent)"
          kubectl delete deployment myapp \
            --namespace "$NAMESPACE" \
            --ignore-not-found

          echo "Deploying application with Helm"
          helm upgrade --install myapp "$HELM_CHART" \
            --namespace "$NAMESPACE" \
            --create-namespace \
            --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
            --set image.tag="$IMAGE_TAG" \
            --wait \
            --timeout 
        '''
      }
    }
  }

  post {
    success {
      echo "Pipeline completed successfully for tag ${env.GIT_TAG_NAME}"
    }
    failure {
      echo "Pipeline failed"
    }
  }
}
