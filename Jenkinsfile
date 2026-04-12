pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  parameters {
    choice(
      name: 'VERSION',
      choices: ['auto', 'v1', 'v2'],
      description: 'auto = derive from branch, otherwise force version'
    )
  }

  environment {
    ACR_NAME    = "starterkitacr"
    IMAGE_NAME  = "myapp"
    IMAGE_TAG   = ""

    DOCKER_HOST = "10.10.1.5"
    DOCKER_USER = "vinadmin"

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

    stage('Prepare version') {
      steps {
        script {
          def branch = env.BRANCH_NAME ?: 'main'
          echo "Branch: ${branch}"

          // Handle empty-string parameters correctly
          def versionParam = params?.VERSION
          if (versionParam == null || versionParam.trim().length() == 0) {
            versionParam = 'auto'
          }

          if (versionParam == 'auto') {
            env.IMAGE_TAG = (branch == 'main') ? 'v1' : 'v2'
          } else {
            env.IMAGE_TAG = versionParam
          }

          // Ultimate safety net
          if (env.IMAGE_TAG == null || env.IMAGE_TAG.trim().length() == 0) {
            env.IMAGE_TAG = 'v1'
          }

          echo "Resolved IMAGE_TAG=${env.IMAGE_TAG}"
        }
      }
    }
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

    stage('Build & Push Image (Docker VM)') {
      steps {
        sshagent(credentials: ['docker-server-ssh']) {
          withCredentials([
            string(credentialsId: 'azure-sp-client-id',     variable: 'AZ_CLIENT_ID'),
            string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
            string(credentialsId: 'azure-sp-tenant-id',     variable: 'AZ_TENANT_ID')
          ]) {
            sh """
              ssh -o StrictHostKeyChecking=no ${DOCKER_USER}@${DOCKER_HOST} '
                set -e
                az login --service-principal \
                  -u "$AZ_CLIENT_ID" \
                  -p "$AZ_CLIENT_SECRET" \
                  --tenant "$AZ_TENANT_ID"

                az acr login --name ${ACR_NAME}

                docker build \
                  --build-arg APP_VERSION=${IMAGE_TAG} \
                  -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .

                docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
              '
            """
          }
        }
      }
    }

    stage('Quality & Security Gates (v2)') {
      when {
        expression { env.IMAGE_TAG == 'v2' }
      }
      steps {
        sh '''
          echo "Running v2 checks"
          grep -qi "<html" app/index.html
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

          az aks get-credentials \
            --resource-group "$AKS_RG" \
            --name "$AKS_NAME" \
            --overwrite-existing

          kubectl delete deployment myapp \
            --namespace "$NAMESPACE" \
            --ignore-not-found

          helm upgrade --install myapp "$HELM_CHART" \
            --namespace "$NAMESPACE" \
            --create-namespace \
            --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
            --set image.tag="$IMAGE_TAG" \
            --wait \
            --timeout 5m
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Deployment of ${env.IMAGE_TAG ?: 'unknown'} completed successfully"
    }
    failure {
      echo "❌ Pipeline failed for ${env.IMAGE_TAG ?: 'unknown'}"
    }
  }
}






// pipeline {
//   agent any

//   options {
//     timestamps()
//     disableConcurrentBuilds()
//     buildDiscarder(logRotator(numToKeepStr: '30'))
//   }

//   parameters {
//     choice(
//       name: 'VERSION',
//       choices: ['auto', 'v1', 'v2'],
//       description: 'auto = derive from branch, otherwise force version'
//     )
//   }

//   environment {
//     // ACR / Image
//     ACR_NAME    = "starterkitacr"
//     IMAGE_NAME  = "myapp"

//     IMAGE_TAG   = ""   // computed in Prepare

//     // Docker build VM
//     DOCKER_HOST = "10.10.1.5"
//     DOCKER_USER = "vinadmin"

//     // AKS
//     AKS_RG      = "sk-dev2-rg"
//     AKS_NAME    = "sk-dev2-aks"
//     HELM_CHART  = "helm/myapp"
//     NAMESPACE   = "default"
//   }

//   stages {

//     stage('Checkout') {
//       steps {
//         checkout scm
//       }
//     }

//     stage('Prepare version') {
//       steps {
//         script {
//           def branch = env.BRANCH_NAME ?: 'main'
//           echo "Branch: ${branch}"

//           // Safe, defensive parameter handling
//           def versionParam = (params?.VERSION ?: 'auto').toString().trim()

//           if (versionParam == 'auto') {
//             env.IMAGE_TAG = (branch == 'main') ? 'v1' : 'v2'
//           } else {
//             env.IMAGE_TAG = versionParam
//           }

//           // Absolute safety fallback
//           if (!env.IMAGE_TAG?.trim()) {
//             env.IMAGE_TAG = 'v1'
//           }

//           echo "Resolved IMAGE_TAG=${env.IMAGE_TAG}"
//         }
//       }
//     }
//     stage('Build Readiness Check') {
//       steps {
//         sh '''
//           set -e
//           test -f Dockerfile
//           test -f app/index.html
//           test -f helm/myapp/Chart.yaml
//         '''
//       }
//     }

//     stage('Build & Push Image (Docker VM)') {
//       steps {
//         sshagent(credentials: ['docker-server-ssh']) {
//           withCredentials([
//             string(credentialsId: 'azure-sp-client-id',     variable: 'AZ_CLIENT_ID'),
//             string(credentialsId: 'azure-sp-client-secret', variable: 'AZ_CLIENT_SECRET'),
//             string(credentialsId: 'azure-sp-tenant-id',     variable: 'AZ_TENANT_ID')
//           ]) {
//             sh """
//               ssh -o StrictHostKeyChecking=no ${DOCKER_USER}@${DOCKER_HOST} '
//                 set -e
//                 az login --service-principal \
//                   -u "$AZ_CLIENT_ID" \
//                   -p "$AZ_CLIENT_SECRET" \
//                   --tenant "$AZ_TENANT_ID"

//                 az acr login --name ${ACR_NAME}

//                 docker build \
//                   --build-arg APP_VERSION=${IMAGE_TAG} \
//                   -t ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG} .

//                 docker push ${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}
//               '
//             """
//           }
//         }
//       }
//     }

//     stage('Quality & Security Gates (v2)') {
//       when {
//         expression { env.IMAGE_TAG == 'v2' }
//       }
//       steps {
//         sh '''
//           echo "Running v2 checks"
//           grep -qi "<html" app/index.html
//         '''
//       }
//     }

//     stage('Approve Deployment (v2)') {
//       when {
//         expression { env.IMAGE_TAG == 'v2' }
//       }
//       steps {
//         input message: "Approve v2 deployment to AKS?", ok: "Deploy"
//       }
//     }

//     stage('Deploy to AKS') {
//       steps {
//         sh '''
//           set -e

//           az aks get-credentials \
//             --resource-group "$AKS_RG" \
//             --name "$AKS_NAME" \
//             --overwrite-existing

//           kubectl delete deployment myapp \
//             --namespace "$NAMESPACE" \
//             --ignore-not-found

//           helm upgrade --install myapp "$HELM_CHART" \
//             --namespace "$NAMESPACE" \
//             --create-namespace \
//             --set image.repository="$ACR_NAME.azurecr.io/$IMAGE_NAME" \
//             --set image.tag="$IMAGE_TAG" \
//             --wait \
//             --timeout 5m
//         '''
//       }
//     }
//   }

//   post {
//     success {
//       echo " Deployment of ${env.IMAGE_TAG ?: 'unknown'} completed successfully"
//     }
//     failure {
//       echo " Pipeline failed for ${env.IMAGE_TAG ?: 'unknown'}"
//     }
//   }
// }