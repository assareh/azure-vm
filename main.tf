variable "tfc_organization" {

}

variable "tfc_subnet_workspace" {

}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.59.0"
    }
  }
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
value = module.linuxservers.vm_names["linux"][0]
}

resource "random_pet" "server" {
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_storage_account" "example" {
  name                     = "${random_pet.server.id}-storageaccount"
  resource_group_name = data.azurerm_resource_group.example.name
  location                 = data.azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "example" {
  name                = "${random_pet.server.id}-appinsights"
  resource_group_name = data.azurerm_resource_group.example.name
  location                 = data.azurerm_resource_group.example.location
  application_type    = "web"
}

resource "azurerm_service_plan" "example" {
  name                = "${random_pet.server.id}-sp"
  location                 = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${random_pet.server.id}-LFA"
  location                 = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
  service_plan_id     = azurerm_service_plan.example.id

  storage_account_name       = azurerm_storage_account.example.name
  storage_account_access_key = azurerm_storage_account.example.primary_access_key

  site_config {
    application_insights_connection_string = azurerm_application_insights.example.connection_string
  }
}

data "azurerm_linux_function_app" "example" {
  name                = azurerm_linux_function_app.example.name
  resource_group_name = azurerm_linux_function_app.example.resource_group_name
}

check "check_vm_state" {
  assert {
    condition = data.azurerm_linux_function_app.example.usage == "Exceeded"
    error_message = format("Function App (%s) usage has been exceeded!",
      data.azurerm_linux_function_app.example.id,
    )
  }
}
