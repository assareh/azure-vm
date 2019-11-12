terraform {
  required_version = ">= 0.12"
}

variable "location" {
  description = "Azure location in which to create resources"
  default     = "West US"
}

variable "windows_dns_prefix" {
  description = "DNS prefix to add to to public IP address for Windows VM"
}

variable "admin_password" {
  description = "admin password for Windows VM"
  default     = "pTFE1234!"
}

variable "ssh_key" {
  description = "ssh public key"
}

module "windowsservers" {
  source              = "Azure/compute/azurerm"
  version             = "1.3.0"
  location            = var.location
  resource_group_name = "${var.windows_dns_prefix}-rc"
  vm_hostname         = "pwc-ptfe"
  admin_password      = var.admin_password
  vm_os_simple        = "WindowsServer"
  public_ip_dns       = [var.windows_dns_prefix]
  vnet_subnet_id      = module.network.vnet_subnets[0]
  ssh_key             = var.ssh_key
}

module "network" {
  source              = "Azure/network/azurerm"
  version             = "2.0.0"
  location            = var.location
  resource_group_name = "${var.windows_dns_prefix}-rc"
}

output "windows_vm_public_name" {
  value = module.windowsservers.public_ip_dns_name
}

