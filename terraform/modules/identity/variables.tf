
variable "issuer" {
  description = "The issuer URL for the federated identity credential"
  type        = string
}

variable "subject" {
  description = "The subject for the federated identity credential"
  type        = string
}

variable "name_prefix" {
  description = "The name prefix for resources"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location"
  type        = string
}