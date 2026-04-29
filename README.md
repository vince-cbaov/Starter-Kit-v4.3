
# Starter Kit v4.3

**Azure Dev & Production CI/CD with Terraform, Ansible, Jenkins, Docker, Helm, AKS, and Key Vault**

***

## Overview

**Starter Kit v4.3** is a production‑style DevOps reference project demonstrating how to design, provision, and operate **separate Dev and Production environments on Microsoft Azure** using modern CI/CD and Infrastructure‑as‑Code practices.

The repository shows how to:

*   Provision **isolated Dev and Prod environments**
*   Use **Terraform modules consistently** across environments
*   Configure infrastructure using **Ansible**
*   Build container images remotely using **Docker**
*   Deploy applications to **AKS using Helm**
*   Secure secrets with **Azure Key Vault (RBAC + CSI)**
*   Promote application versions safely between environments

The project structure and workflows reflect how real‑world Azure DevOps platforms are typically built and operated.

***

## Applications

### 1. Static CI/CD Web App (Deployed to AKS)

This application is containerised and deployed to **AKS** by the Jenkins pipeline.  
It supports **versioned deployments (v1 and v2)** and can be promoted independently to Dev or Prod.

**Application versions**

    app/v1/index.html
    app/v1/index_apply.html

    app/v2/index.html
    app/v2/index_apply.html
    app/v2/index_with_logo.html

    app/v1/devops-logo.png
    app/v2/devops-logo.png

**Key characteristics**

*   One version (v1 or v2) is deployed per pipeline run
*   Version and target environment are controlled by pipeline logic or runtime input
*   Runs in an **NGINX container**
*   Deployed using **Helm**
*   The **same container image** is promoted from Dev to Prod (immutable artifact)

***

### 2. Flask Portfolio App (Local‑Only)

A simple Flask application included for local testing, experimentation, or future extension.

This application:

*   Is **not deployed via CI/CD**
*   Does not run in AKS
*   Is intentionally isolated from Dev/Prod pipelines

<!---->

    app/flask-portfolio/
    ├── app.py
    ├── templates/
    │   ├── index.html
    │   └── apply.html
    └── static/
        ├── styles.css
        └── devops-logo.png

***

## Dev and Prod Environment Model

This project implements **two fully isolated environments**:

| Environment | Purpose                               |
| ----------- | ------------------------------------- |
| **Dev**     | Development, testing, experimentation |
| **Prod**    | Stable, production‑like environment   |

Each environment has:

*   Its own **Resource Group**
*   Its own **AKS cluster**
*   Its own **Azure Key Vault**
*   Independent networking where required
*   Shared Terraform modules with environment‑specific variables

***

## Repository Structure (High Level)

    starter_kit_v4_3/
    │
    ├── terraform/
    │   ├── envs/
    │   │   ├── dev/
    │   │   └── prod/
    │   ├── modules/
    │   │   ├── resource_group/
    │   │   ├── network/
    │   │   ├── acr/
    │   │   ├── aks/
    │   │   ├── monitoring/
    │   │   ├── key_vault/
    │   │   └── compute/
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── versions.tf
    │   └── COMPOSITION.tf
    │
    ├── ansible/
    │   ├── inventory/
    │   │   ├── dev.ini
    │   │   └── prod.ini
    │   ├── playbooks/
    │   └── roles/
    │       ├── hardening/
    │       ├── docker_server/
    │       ├── jenkins/
    │       └── jcasc/
    │
    ├── app/
    │   ├── v1/
    │   ├── v2/
    │   └── flask-portfolio/
    │
    ├── k8s/
    ├── helm/
    ├── scripts/
    ├── docs/
    ├── Jenkinsfile
    ├── evidence_checklist_v4_3.html
    └── README.md

***

## Secret Management and Identity Model

Secrets are **never stored in Git** and are handled differently depending on **where the code is running**.

### Runtime Secret Handling

Secrets are:

1.  Supplied via environment variables at Terraform runtime
2.  Stored securely in **Azure Key Vault (per environment)**
3.  Consumed by Jenkins or AKS workloads at runtime

#### Required Runtime Variables

```bash
export SP_APP_ID="<GUID>"
export SP_SECRET="<secret>"
export TENANT_ID="<GUID>"
export SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
```

Key Vault stores values such as:

*   `acr-sp-app-id`
*   `acr-sp-secret`
*   `tenant-id`
*   `acr-name`

***

### Identity Usage by Context

This project uses **different Azure identity mechanisms depending on the execution context**, reflecting common real‑world Azure architectures.

#### Jenkins (CI/CD Control Plane)

*   Jenkins runs on a **Virtual Machine**, outside of AKS
*   Jenkins authenticates to Azure using an **Azure Service Principal**
*   The Service Principal is stored securely as a Jenkins credential
*   Used for:
    *   `az login`
    *   Azure Container Registry access
    *   `az aks get-credentials`
    *   Terraform and Helm operations

#### AKS Workloads (Runtime Plane)

*   Applications running inside AKS use a **User‑Assigned Managed Identity (UAMI)**
*   Authentication is handled via **Azure Workload Identity (OIDC federation)**
*   No client secrets or credentials are stored in pods
*   Used for:
    *   Azure Key Vault CSI driver
    *   Secure pod‑to‑Azure resource access

This separation ensures:

*   Secretless authentication for Kubernetes workloads
*   Appropriate identity usage for CI/CD tooling
*   Clear separation between infrastructure control and application runtime security

***

## Provisioning the Dev Environment

```bash
cd terraform/envs/dev
terraform init -backend-config=backend.tfvars
terraform apply -auto-approve
```

### Resources Created

*   Resource Group
*   Virtual Network, Subnets, NSGs
*   Azure Container Registry
*   Azure Kubernetes Service
*   Azure Key Vault (RBAC)
*   Log Analytics Workspace
*   Docker Build VM (remote Docker API)
*   Optional Jenkins VM

***

## Provisioning the Prod Environment

```bash
cd terraform/envs/prod
terraform init -backend-config=backend.tfvars
terraform apply -auto-approve
```

Prod uses the **same Terraform modules** as Dev, with stricter environment‑specific values.

***

## VM Access and Jenkins Setup

```bash
nc -vz <docker_ip> 22
nc -vz <jenkins_ip> 22
ssh vinadmin@<jenkins_ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins:

    http://<jenkins_ip>:8080

***

## Ansible Configuration (Dev & Prod)

```bash
cd ansible
ansible -i inventory/dev.ini all -m ping
ansible-playbook -i inventory/dev.ini site.yml
```

Repeat with `prod.ini` for production.

***

## Jenkins Pipeline

### Pipeline Behaviour

The `Jenkinsfile` performs:

1.  Source checkout
2.  Azure authentication (Service Principal)
3.  ACR login
4.  Remote Docker image build on Docker Server VM
5.  Push image to ACR
6.  `az aks get-credentials`
7.  Helm deploy to AKS
8.  Rollout verification

The pipeline supports **Dev → Prod promotion** using the same immutable image.

***

## Jenkins Requirements

**Plugins**

*   Docker Pipeline
*   Docker API / Commons
*   Azure CLI
*   Azure Credentials
*   Kubernetes CLI
*   Git Plugin
*   Pipeline: Declarative
*   Credentials Binding

***

## AKS + Azure Key Vault CSI

```bash
az aks enable-addons -g <rg> -n <aks> --addons azure-keyvault-secrets-provider
kubectl apply -f k8s/csi/secretproviderclass-dev.yaml
kubectl apply -f k8s/csi/secretproviderclass-prod.yaml
```

Secrets mount at:

    /mnt/secrets

***

## Running the Flask App Locally

```bash
cd app/flask-portfolio
pip install flask
python app.py
```

***

## Evidence Checklist

Located in:

    evidence_checklist_v4_3.html

Covers:

*   Terraform infrastructure deployment
*   Azure Key Vault secret handling
*   Jenkins authentication and pipeline execution
*   Remote Docker builds
*   ACR image push
*   AKS deployment
*   Versioned (v2) deployment controls

***

## Security Notes

*   Dev and Prod environments are isolated
*   Docker API access restricted to Jenkins VM
*   No secrets stored in Git or baked into images
*   AKS uses managed identity with `AcrPull`
*   Terraform state is environment‑specific

***

## Optional Enhancements

*   Approval gates Dev → Prod
*   AKS Ingress with HTTPS
*   Jenkins → Managed Identity migration
*   GitHub Actions support
*   Blue/green or canary deployments

***

### ✅ Summary

This repository demonstrates a **modern Azure Dev and Production CI/CD platform**, combining Infrastructure as Code, secure identity patterns, and Kubernetes‑native best practices.
