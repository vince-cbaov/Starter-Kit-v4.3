pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    skipDefaultCheckout()
  }

  parameters {
    choice(
      name: 'VERSION',
      choices: ['auto', 'v1', 'v2'],
      description: 'auto = derive from branch, otherwise force version'
    )
  }

  environment {
    // ACR / Image (do NOT pre-seed IMAGE_TAG)
    ACR_NAME   = "starterkitacr"
    IMAGE_NAME = "myapp"

    // Docker build VM
    DOCKER_HOST = "10.10.1.5"
    DOCKER_USER = "vinadmin"

    // AKS configuration
    AKS_RG     = "sk-dev2-rg"
    AKS_NAME   = "sk-dev2-aks"
    HELM_CHART = "helm/myapp"
    NAMESPACE  = "default"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Bootstrap Azure Identity') {
      steps {
        script {
          def output = powershell(
            script: '.\\scripts\\bootstrap-identity.ps1',
            returnStdout: true
          ).trim()

          output.split("\n").each { line ->
            def (key, value) = line.split("=", 2)
            env."${key}" = value
          }
        }
      }
    }

    stage('Prepare version') {
      steps {
        script {
          def branch = env.BRANCH_NAME ?: 'main'
          echo "Resolved branch: ${branch}"
          echo "Raw VERSION param: '${params.VERSION}'"

          def versionParam = params.VERSION
          if (!versionParam?.trim()) {
            versionParam = 'auto'
          }

          def resolvedTag
          if (versionParam == 'auto') {
            resolvedTag = (branch == 'main') ? 'v1' : 'v2'
          } else {
            resolvedTag = versionParam
          }

          if (!resolvedTag?.trim()) {
            resolvedTag = 'v1'
          }

          env.IMAGE_TAG = resolvedTag
          echo "Resolved IMAGE_TAG=${env.IMAGE_TAG}"
        }
      }
    }

    stage('Build Readiness Check') {
      steps {
        sh '''
          set -e
          test -f Dockerfile
          test -d "app/$IMAGE_TAG"
          test -f "app/$IMAGE_TAG/index.html"
          test -f helm/myapp/Chart.yaml
        '''
      }
    }

    stage('Build & Push Image (Docker VM)') {
      steps {
        sshagent(credentials: ['docker-server-ssh']) {
          sh '''
            set -e
            tar -czf - . | ssh -o StrictHostKeyChecking=no '"${DOCKER_USER}@${DOCKER_HOST}"' '
              set -e
              az login --identity
              az acr login --name '"${ACR_NAME}"'

              docker build \
                -f Dockerfile \
                --build-arg APP_VERSION='"${IMAGE_TAG}"' \
                -t '"${ACR_NAME}"'.azurecr.io/'"${IMAGE_NAME}"':'"${IMAGE_TAG}"' -

              docker push '"${ACR_NAME}"'.azurecr.io/'"${IMAGE_NAME}"':'"${IMAGE_TAG}"'
            '
          '''
        }
      }
    }

    stage('Quality & Security Gates (v2)') {
      when {
        expression { env.IMAGE_TAG == 'v2' }
      }
      steps {
        sh '''
          echo "Running v2 quality checks"
          grep -qi "<html" app/v2/index.html
        '''
      }
    }

    stage('Approve Deployment (v2)') {
      when {
        expression { env.IMAGE_TAG == 'v2' }
      }
      steps {
        input message: "Approve v2 deployment to AKS?", ok: "Deploy"
      }
    }

    stage('Deploy to AKS') {
      steps {
        sh '''
          set -e
          az login --identity

          az aks get-credentials \
            --resource-group "$AKS_RG" \
            --name "$AKS_NAME" \
            --overwrite-existing

          helm upgrade --install myapp "$HELM_CHART" \
            --namespace "$NAMESPACE" \
            --create-namespace \
            --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
            --set image.tag="$IMAGE_TAG" \
            --wait \
            --timeout 10m
        '''
      }
    }
  }

  post {
    success {
      echo " Deployment of ${env.IMAGE_TAG} completed successfully"
    }
    failure {
      echo " Pipeline failed for ${env.IMAGE_TAG ?: 'unknown'}"
    }
  }
}