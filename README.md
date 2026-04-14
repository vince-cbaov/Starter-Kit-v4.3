# Starter Kit v4.3 (Runtime‑Input + Docker Server + Branding + Updated Deployment Flow)

This repository contains a complete, production‑style DevOps starter kit that demonstrates the full CI/CD lifecycle on Azure using Terraform, Jenkins, Docker, Helm, AKS, and Azure Key Vault. It also includes two applications:

***

## Applications

### 1. **Static CI/CD Web App (deployed by the pipeline)**

This application is deployed to AKS via the Jenkins pipeline and supports **versioned deployments (v1 and v2)**.

*   `app/v1/index.html` – v1 homepage
*   `app/v1/index_apply.html` – v1 Apply & Prove page
*   `app/v2/index.html` – v2 homepage
*   `app/v2/index_apply.html` – v2 Apply & Prove page
*   `app/v2/index_with_logo.html` – v2 branded splash page
*   `app/v1/devops-logo.png`, `app/v2/devops-logo.png` – shared branding assets

The pipeline deploys **either v1 or v2 per run**, based on branch logic or runtime input.

***

### 2. **Flask Portfolio App (local use, not deployed by CI/CD)**

This application is used for **portfolio and EPA evidence only** and is not part of the CI/CD pipeline.

*   `app/flask-portfolio/app.py`
*   Templates: `index.html`, `apply.html`
*   Static assets: `styles.css`, `devops-logo.png`

***

## The Starter Kit Incorporates

*   Full infrastructure deployment using Terraform
*   VM configuration using Ansible (Docker Server + optional Jenkins)
*   Application deployment to AKS using Helm
*   Secure runtime secrets using Azure Key Vault CSI
*   CI/CD using Jenkins or GitHub Actions (optional)
*   A structured, EPA‑compliant evidence trail

***

## Folder Structure (High Level)

    starter_kit_v4_3/
    │
    ├── terraform/
    │   ├── main.tf
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── COMPOSITION.tf
    │   ├── versions.tf
    │   ├── envs/{dev,prod}/
    │   └── modules/{resource_group,network,acr,aks,monitoring,key_vault,compute}/
    │
    ├── ansible/
    │   ├── inventory/
    │   ├── playbooks/
    │   └── roles/{hardening,docker_server,jenkins,jcasc}/
    │
    ├── app/
    │   ├── flask-portfolio/
    │   │   ├── static/{styles.css,devops-logo.png}
    │   │   ├── templates/{index.html,apply.html}
    │   │   └── app.py
    │   ├── v1/
    │   │   ├── index.html
    │   │   ├── index_apply.html
    │   │   └── devops-logo.png
    │   ├── v2/
    │   │   ├── index.html
    │   │   ├── index_apply.html
    │   │   ├── index_with_logo.html
    │   │   └── devops-logo.png
    │   └── README.txt
    │
    ├── k8s/
    ├── helm/
    ├── scripts/
    ├── docs/
    ├── Jenkinsfile
    ├── evidence_checklist_v4_3.html
    └── README.md

***

## Secrets — Runtime‑Input Model

No secrets are stored in the repository. Secrets are supplied at Terraform runtime using environment variables:

```bash
export SP_APP_ID="<GUID>"
export SP_SECRET="<secret>"
export TENANT_ID="<GUID>"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
```

The Terraform Key Vault module stores these as:

*   `acr-sp-app-id`
*   `acr-sp-secret`
*   `tenant-id`
*   `acr-name`

These secrets are later consumed by AKS pods using the Key Vault CSI driver or by Jenkins during pipeline execution.

***

## Provision Infrastructure (dev)

Move to the dev environment:

```bash
cd terraform/envs/dev
```

Initialise backend:

```bash
terraform init -backend-config=backend.tfvars
```

Deploy infrastructure:

```bash
terraform apply -auto-approve \
  -var="location=northeurope" \
  -var="name_prefix=sk-dev" \
  -var="admin_username=vinadmin" \
  -var="acr_name=starterkitacr" \
  -var="sp_app_id=$SP_APP_ID" \
  -var="sp_secret=$SP_SECRET" \
  -var="tenant_id=$TENANT_ID" \
  -var="ssh_public_key=$SSH_PUBLIC_KEY" \
  -var="create_vms=true" \
  -var="enable_docker_vm=true"
```

This creates:

*   Resource Group
*   Virtual Network, Subnet, NSG
*   Azure Container Registry
*   Azure Kubernetes Service
*   Azure Key Vault (RBAC)
*   Log Analytics Workspace
*   Docker Build VM (remote Docker API)
*   Optional Jenkins VM

***

## Accessing the VMs and Unlocking Jenkins

Test VM ports:

```bash
nc -vz <docker_ip> 22
nc -vz <jenkins_ip> 22
```

SSH:

```bash
ssh vinadmin@<jenkins_ip>
```

Retrieve Jenkins unlock password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open Jenkins:

    http://<jenkins_ip>:8080

***

## Ansible Server Configuration

Ansible inventories live under `ansible/inventory/`.

To configure the Docker Server and Jenkins:

```bash
cd ansible
ansible -i inventory.ini all -m ping
ansible-playbook -i inventory.ini site.yml
```

### Roles Applied

*   Hardening
*   Docker Server
*   Jenkins
*   Jenkins Configuration as Code (JCasC)

***

## Jenkins + Azure Key Vault

### Required Plugins

Not included by default:

*   Docker Pipeline
*   Docker API
*   Docker Commons
*   Azure CLI
*   Azure Credentials
*   Kubernetes CLI
*   Git Plugin
*   Pipeline: Declarative
*   Credentials Binding

### Create Service Principal Credential

In Jenkins:

*   ID: `azure-sp`
*   Type: Secret Text
*   Paste the full JSON output from:

```bash
az ad sp create-for-rbac --sdk-auth
```

### Pipeline Behaviour

The Jenkinsfile performs:

1.  Source checkout
2.  Azure login using Service Principal
3.  ACR login
4.  Remote Docker build on the Docker Server VM
5.  Push image to ACR
6.  `az aks get-credentials`
7.  Helm deploy to AKS
8.  Rollout verification

***

## Static CI/CD App (Deployed to AKS)

The CI/CD app consists of:

    app/v1/index.html
    app/v1/index_apply.html
    app/v2/index.html
    app/v2/index_apply.html
    app/v2/index_with_logo.html
    app/*/devops-logo.png

Notes:

*   Only **one version (v1 or v2)** is deployed per pipeline run
*   `index_with_logo.html` is referenced internally only
*   Deployment uses an NGINX container defined in Helm

***

## Flask Portfolio App (Local Only)

This app is not part of CI/CD and is intended for local execution only.

```bash
cd app/flask-portfolio
pip install flask
python app.py
```

Open:

    http://127.0.0.1:5000/

***

## AKS + Azure Key Vault CSI

Enable CSI driver:

```bash
az aks enable-addons -g <rg> -n <aks> --addons azure-keyvault-secrets-provider
```

Apply SecretProviderClass:

```bash
kubectl apply -f k8s/csi/secretproviderclass.yaml
```

Secrets are mounted in pods at:

    /mnt/secrets

***

## Evidence Checklist

Located in `evidence_checklist_v4_3.html`.

Covers:

*   Terraform deployment
*   Key Vault secret handling
*   Jenkins authentication
*   Remote Docker builds
*   ACR image push
*   AKS deployment
*   v2 quality gates and approvals

***

## Security Notes

*   Restrict Docker API access to Jenkins VM only
*   Use TLS (2376) for production Docker
*   Never store secrets in the repository
*   Use managed identity with `AcrPull` for AKS → ACR

***

## Support and Extensions

Available on request:

*   TLS‑enabled Docker remote API
*   AKS Ingress with HTTPS
*   External Secrets Operator
*   Monitoring dashboards
*   Flask deployment to AKS
*   Multi‑environment pipeline support (dev/prod)

***
