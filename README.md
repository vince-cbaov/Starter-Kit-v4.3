# Starter Kit v4.3 (Runtime-Input + Docker Server + Branding)

This repository contains a complete, production‑style DevOps starter kit that demonstrates the full CI/CD lifecycle on Azure using Terraform, Jenkins, Docker, Helm, AKS, and Azure Key Vault. It also includes two applications:

*   A **static CI/CD web app** (deployed by the pipeline):
    *   `app/index.html` → v1 homepage (simple black page)
    *   `app/index_apply.html` → full Apply & Prove page (Modules 4–6), includes v2 splash
    *   `app/index_with_logo.html` → v2 splash (not deployed standalone)
    *   `app/devops-logo.png` → shared asset

*   A **Flask portfolio app** for local usage and EPA evidence (not deployed by CI/CD):
    *   `app/flask-portfolio/app.py`
    *   `app/flask-portfolio/templates/{index.html, apply.html}`
    *   `app/flask-portfolio/static/{styles.css, devops-logo.png}`

***

## **Folder Structure (High Level)**

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
    │   └── roles/{hardening,docker,docker_server,jenkins,jcasc}/
    │
    ├── app/
    │   ├── flask-portfolio/
    │   │   ├── static/{styles.css,devops-logo.png}
    │   │   ├── templates/{index.html,apply.html}
    │   │   └── app.py
    │   ├── index.html                 # v1 (CI/CD homepage)
    │   ├── index_apply.html           # CI/CD full page (includes v2)
    │   ├── index_with_logo.html       # v2 splash (not standalone in CI/CD)
    │   └── devops-logo.png
    │
    ├── k8s/
    ├── helm/
    ├── scripts/
    ├── docs/
    ├── Jenkinsfile
    ├── evidence_checklist_v4_3.html
    └── README.md

***

## **Secrets — Runtime‑Input Model**

No secrets are stored in the repository. They must be supplied at Terraform apply-time:

```bash
export SP_APP_ID="<GUID>"
export SP_SECRET="<secret>"
export TENANT_ID="<GUID>"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
```

Terraform writes into Key Vault:

*   `acr-sp-app-id`
*   `acr-sp-secret`
*   `tenant-id`
*   `acr-name`

***

## **Provision Infrastructure (dev)**

```bash
cd terraform/envs/dev
terraform init -backend-config=backend.tfvars

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

Creates:  
Resource Group, VNet, Subnet, NSG, ACR, AKS, Key Vault, Log Analytics Workspace, and a Docker Build VM (remote API at `tcp://<docker-ip>:2375`).

***

## **Jenkins + Azure Key Vault**

1.  Install Jenkins plugins:
    *   Azure Credentials
    *   Azure Key Vault
    *   Docker
    *   Git
    *   Pipeline

2.  Create Jenkins credential:
    *   ID: `azure-sp`
    *   Type: Azure Service Principal

3.  Set build parameters:
    *   `KV_URL = https://<kv_name>.vault.azure.net/`
    *   `DOCKER_SERVER_IP = <docker_vm_ip>`

The Jenkinsfile:

*   Fetches secrets from Key Vault
*   Builds on the remote Docker VM
*   Pushes to ACR
*   Deploys to AKS via Helm
*   Confirms rollout

***

## **Static CI/CD App (What the Pipeline Deploys)**

CI/CD publishes ONLY the static site located in the root of `/app`:

    app/index.html          # v1 homepage
    app/index_apply.html    # main Apply & Prove page (contains v2)
    app/devops-logo.png

`index_with_logo.html` (v2 splash) is only referenced inside `index_apply.html`; it is **not deployed separately**.

Deployment options:

*   NGINX container on AKS
*   Azure Storage Static Website
*   Any static hosting platform

***

## **Flask Portfolio App (Local Use)**

To run locally:

```bash
cd app/flask-portfolio
pip install flask
python app.py
```

Accessible at `http://127.0.0.1:5000/`.

This app is used for:

*   EPA evidence
*   Local demonstrations
*   Portfolio UI

It is not deployed by CI/CD unless containerised separately.

***

## **AKS + Azure Key Vault CSI**

Enable AKV CSI and mount secrets into workloads:

```bash
az aks enable-addons -g <rg> -n <aks> --addons azure-keyvault-secrets-provider

sed -e "s/KV_NAME_TO_FILL/$(terraform -chdir=.. output -raw kv_name)/" \
    -e "s/TENANT_ID_TO_FILL/$TENANT_ID/" \
    k8s/csi/secretproviderclass.tmpl.yaml | kubectl apply -f -
```

***

## **Evidence Checklist**

Use `evidence_checklist_v4_3.html` to collect all Apply & Prove evidence:

*   Terraform execution
*   Key Vault secrets
*   Jenkins Key Vault usage
*   Docker VM remote build
*   ACR push
*   AKS rollout success
*   Optional CSI secret mount evidence

***

## **Security Notes**

*   Lock Docker API port 2375 to **Jenkins VM only**.
*   Prefer TLS/2376 if needed in production.
*   Never store secrets in the repo.
*   Use MSI‑based AcrPull permissions for AKS → ACR.

***

## **Support and Extensions**

Available on request:

*   TLS-enabled Docker API
*   AKS Ingress with TLS
*   External Secrets Operator
*   Monitoring dashboard (`/monitor`)
*   Deploying Flask to AKS
*   Additional pipeline environments

***

If you want a **README.md for the Flask app**, or a **README.md for CI/CD only**, or a **shorter README**, I can generate that too.
