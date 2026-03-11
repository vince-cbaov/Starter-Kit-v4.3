variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type    = string
  default = ""
}

variable "acr_name" {
  type = string
}

variable "sp_app_id" {
  type = string
}

variable "sp_secret" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "create_vms" {
  type    = bool
<<<<<<< HEAD
<<<<<<< HEAD
  default = false
=======
  default = true
>>>>>>> origin/main
=======
  default = false
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
}

variable "enable_docker_vm" {
  type    = bool
  default = true
<<<<<<< HEAD
<<<<<<< HEAD
}
<<<<<<< HEAD
=======
}
>>>>>>> origin/main
=======
=======
}
>>>>>>> origin/dev

variable "sp_object_id" {
  description = "Object ID of the service principal (principal_id) that runs Terraform"
  type        = string
<<<<<<< HEAD
}
>>>>>>> 0b58b27ab7c0049cc96e4fa5d46b6d765ceee0e9
=======
}
>>>>>>> origin/dev
