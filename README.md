# Starter Kit v4.3 (Runtime-Input + Docker Server + Branding + Updated Deployment Flow)

This repository contains a complete, production‑style DevOps starter kit that demonstrates the full CI/CD lifecycle on Azure using Terraform, Jenkins, Docker, Helm, AKS, and Azure Key Vault. It also includes two applications:

### Applications

1.  **Static CI/CD Web App (deployed by the pipeline):**
    *   `app/index.html` – v1 homepage
    *   `app/index_apply.html` – full Apply & Prove page (Modules 4–6), includes v2 splash
    *   `app/index_with_logo.html` – v2 splash page (referenced inside Apply page; not deployed alone)
    *   `app/devops-logo.png` – shared asset

2.  **Flask Portfolio App (local use, not deployed by CI/CD):**
    *   `app/flask-portfolio/app.py`
    *   Templates: `index.html`, `apply.html`
    *   Static: `styles.css`, `devops-logo.png`

The Starter Kit now incorporates:

*   Full infrastructure deployment using Terraform
*   VM configuration using Ansible (Docker Server + optional Jenkins)
*   Application deployment to AKS using Helm
*   Secure runtime secrets using Key Vault CSI
*   CI/CD using GitHub Actions or Jenkins (your choice)
*   A structured, EPA-compliant evidence trail

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
    │   └── roles/{hardening,docker,docker_server,jenkins,jcasc}/
    │
    ├── app/
    │   ├── flask-portfolio/
    │   │   ├── static/{styles.css,devops-logo.png}
    │   │   ├── templates/{index.html,apply.html}
    │   │   └── app.py
    │   ├── index.html
    │   ├── index_apply.html
    │   ├── index_with_logo.html
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

## Secrets — Runtime‑Input Model

No secrets are stored in the repository. They must be supplied at Terraform runtime using environment variables:

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

These are later consumed by AKS pods using the Key Vault CSI driver or by Jenkins for pipeline authentication.

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
*   Docker Build VM (`tcp://<docker-ip>:2375` insecure API – lock down with NSG)
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

Open:

    http://<jenkins_ip>:8080

***

## Ansible Server Configuration

Ansible inventories live under `ansible/inventory/`.

To configure Docker Server + Jenkins:

```bash
cd ansible
ansible -i inventory.ini all -m ping
ansible-playbook -i inventory.ini site.yml
```

Roles applied:

*   Hardening
*   Docker server
*   Docker engine
*   Jenkins
*   Jenkins Configuration as Code (JCasC)

***

## Jenkins + Azure Key Vault (Updated Model)

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
*   Paste entire JSON from:

```bash
az ad sp create-for-rbac --sdk-auth
```

### Pipeline Behaviour

The Jenkinsfile performs:

1.  Source checkout
2.  Azure login using SP
3.  ACR login
4.  Remote Docker build on the Docker VM
5.  Push image to ACR
6.  `az aks get-credentials`
7.  Helm deploy to AKS
8.  Rollout verification

***

## Static CI/CD App (Deployed to AKS)

The CI/CD app consists of:

    app/index.html
    app/index_apply.html
    app/devops-logo.png

Notes:

*   `index_with_logo.html` is imported inside `index_apply.html`.
*   It is not deployed as a standalone page.
*   The pipeline copies only these static files into an NGINX container or other hosting method defined in Helm.

Possible deployment methods:

*   NGINX container hosted in AKS (default)
*   Azure Storage Static Website
*   Any static web hosting provider

***

## Flask Portfolio App (Local Only)

This is for portfolio/EPA evidence and not part of the CI/CD pipeline.

Run locally:

```bash
cd app/flask-portfolio
pip install flask
python app.py
```

Open:

    http://127.0.0.1:5000/

***

## AKS + Azure Key Vault CSI (Updated)

Enable CSI driver:

```bash
az aks enable-addons -g <rg> -n <aks> --addons azure-keyvault-secrets-provider
```

Apply SecretProviderClass:

```bash
sed -e "s/KV_NAME_TO_FILL/$(terraform -chdir=.. output -raw kv_name)/" \
    -e "s/TENANT_ID_TO_FILL/$TENANT_ID/" \
    k8s/csi/secretproviderclass.tmpl.yaml | kubectl apply -f -
```

Secrets then appear inside pods at:

    /mnt/secrets

***

## Evidence Checklist

Located in `evidence_checklist_v4_3.html`.

Covers:

*   Terraform deployment
*   Key Vault secrets
*   Jenkins secret retrieval
*   Docker VM remote builds
*   ACR push
*   AKS rollout
*   Optional CSI evidence

***

## Security Notes

*   Restrict Docker API port 2375 to Jenkins VM only.
*   Use TLS (port 2376) for production Docker.
*   Store secrets in Key Vault only, never in repo.
*   Ensure AKS → ACR uses managed identity with AcrPull role.

***

## Support and Extensions

Available on request:

*   TLS-enabled Docker remote API
*   AKS Ingress with HTTPS
*   External Secrets Operator
*   Monitoring dashboards
*   Flask deployment to AKS
*   Multi-environment pipeline support (dev/prod)

***

If you want a shorter README, a CI/CD-specific README, or a separate README for the Flask app, I can generate those as well.
