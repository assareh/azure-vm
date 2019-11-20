terraform {
  required_version = ">= 0.12"
}

variable "location" {
  description = "Azure location in which to create resources"
  default     = "East US"
}

variable "windows_dns_prefix" {
  description = "DNS prefix to add to to public IP address for Windows VM"
}

variable "admin_password" {
  description = "admin password for Windows VM"
  default     = "pTFE1234!"
}

variable "tags" {
  description = "descriptive tags for instances deployed"
  default = {
    "Name" : "Demo Windows VM",
    "owner" : "Andy Assareh",
    "ttl" : "1",
  }
}

module "windowsserver" {
  source              = "Azure/compute/azurerm"
  version             = "1.3.0"
  location            = var.location
  resource_group_name = "${var.windows_dns_prefix}-rc"
  vm_hostname         = "pwc-ptfe"
  admin_password      = var.admin_password
  vm_os_simple        = "WindowsServer"
  is_windows_image    = "true"
  public_ip_dns       = [var.windows_dns_prefix]
  vnet_subnet_id      = module.network.vnet_subnets[0]
  tags                = var.tags
}

module "network" {
  source              = "Azure/network/azurerm"
  version             = "1.1.1"
  location            = var.location
  resource_group_name = "${var.windows_dns_prefix}-rc"
  allow_ssh_traffic   = true
}

output "windows_vm_public_name" {
  value = module.windowsserver.public_ip_dns_name
}

