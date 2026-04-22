variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL from AKS (must be module.aks.oidc_issuer_url)"
  type        = string
}

variable "subject" {
  description = "Kubernetes service account subject (system:serviceaccount:<ns>:<sa>)"
  type        = string
}

variable "subscription_id" {
  type = string
}