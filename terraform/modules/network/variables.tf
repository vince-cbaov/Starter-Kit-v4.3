variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

# Restrict inbound rules on the shared NSG
variable "trusted_cidr" {
  description = "Your office/home IP in CIDR form (e.g., 203.0.113.10/32) used to restrict SSH/Jenkins/Docker."
  type        = string
}