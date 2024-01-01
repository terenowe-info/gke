# Initialize
variable "project_id" {
  type    = string
  default = "seemscloud"
}

variable "project_name" {
  type    = string
  default = "seemscloud"
}

variable "region" {
  type    = string
  default = "europe-central2"
}

variable "region_short" {
  type    = string
  default = "euc2"
}

# Terraform Access
variable "terraform_user" {
  default = "terraform"
  type    = string
}

variable "terraform_user_ssh_pub_key" {
  default = <<EndOfMessage
terraform:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCxMR6x6rHclUBQI3IQVPZN8xjkAVVAZmS1PV/hNg/XPc5sl5fI7/3FLmwu+A9PDuiPu5++60Ns4NtYJcd+hVQ9m/htl6DGPeUoflin1pmVFSfKMUctTRWsl+e2ldt3CVmTgFclLABdLDR+cSb3jSqNXgonzjNcWbTfhrsSnqNuD+2GxXpGZXc4rYDloSrlGVOx0mEiyJrMocJFuVlh1JB8Os0KNnx5qD56h5zIRLGkhHhgXIO5kJ+hNB+vF3FV2Fq9Ar47+DrQiD/o9/h17HFDvD0tzze1GLYAJs4QcFJJPKdWM1kHyXa/p9TIFLc3rVnCrVx1NihgaEhiY+d452otV0p1Bq1tvotfPJ92BDSNlF7A1YuJNYqRkNNpwSPMznPQtVkeRCHTNH5MmMqhPptGEPLiDlkMUZeFFjTKz0IDo6QCX05WBl+SXYLo1l2R9jCoKstmoKvlsFY6fcYpSYj78X9E4bIX++LSLiG9oGXwg2xoZTlwofhqjnI+xc9tMiU=
EndOfMessage
  type    = string
}

# Global
variable "stack_name" {
  type    = string
  default = "sigma"
}

variable "env_name" {
  type    = string
  default = "stg"
}

variable "remote_access_cidr" {
  type    = string
  default = "213.156.101.212/32"
}
