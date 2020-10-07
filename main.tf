terraform {
  required_version = ">= 0.13"
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

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West US 2"
}

module "windowsservers" {
  source  = "Azure/compute/azurerm"
  version = "3.7.0"

  resource_group_name = azurerm_resource_group.example.name
  is_windows_image    = true
  vm_hostname         = "mywinvm" // line can be removed if only one VM module per resource group
  vm_size             = "Standard_DS1_V2"
  admin_password      = "ComplxP@ssw0rd!"
  vm_os_simple        = "WindowsServer"
  public_ip_dns       = ["winsimplevmips"] // change to a unique name per datacenter region
  vnet_subnet_id      = module.network.vnet_subnets[0]

  tags = local.common_tags

  depends_on = [azurerm_resource_group.example]
}

module "network" {
  source  = "Azure/network/azurerm"
  version = "3.2.1"

  resource_group_name = azurerm_resource_group.example.name
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["subnet1"]

  depends_on = [azurerm_resource_group.example]
}

output "windows_vm_public_name" {
  value = module.windowsservers.public_ip_dns_name
}
