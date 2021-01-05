variable "prefix" {
  description = "Name prefix to add to the resources"
  default     = "assareh-hashidemos"
}

variable "region" {
  description = "The region where the resources are created."
  default = {
    AWS   = "us-west-2"
    Azure = "West US 2"
    GCP   = "us-west1"
  }
}

variable "ttl" {
  description = "Value of ttl tag on cloud resources"
}

// Tags
locals {
  common_tags = {
    owner     = "assareh"
    se-region = "AMER - West E2 - R2"
    purpose   = "Demo Terraform and Vault"
    ttl       = var.ttl #hours
    terraform = "true"  # true/false
  }
}
