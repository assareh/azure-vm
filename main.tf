variable "tfc_organization" {

}

variable "tfc_subnet_workspace" {

}

terraform {
  required_version = ">= 0.13"
}

data "tfe_outputs" "subnet" {
  organization = var.tfc_organization
  workspace    = var.tfc_subnet_workspace
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    "Name" : "Demo Windows VM provisioned with Terraform!",
    "owner" : "Andy Assareh",
    "ttl" : "1",
    "Description" : "This is a customer8 description",
  }
}

data "azurerm_resource_group" "example" {
  name = data.tfe_outputs.subnet.values.rg_name
}

data "azurerm_subnet" "example" {
  name                 = data.tfe_outputs.subnet.values.subnet_name
  virtual_network_name = data.tfe_outputs.subnet.values.vnet_name
  resource_group_name  = data.azurerm_resource_group.example.name
}

module "linuxservers" {
  source              = "Azure/compute/azurerm"
  resource_group_name = data.azurerm_resource_group.example.name
  vm_os_simple        = "UbuntuServer"
  public_ip_dns       = [random_pet.server.id] // change to a unique name per datacenter region
  vnet_subnet_id      = data.azurerm_subnet.example.id
  enable_ssh_key      = false
  admin_password      = random_password.password.result
}

output "vm_names" {
value = module.linuxservers.vm_names
}

resource "random_pet" "server" {
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
