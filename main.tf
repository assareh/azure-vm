provider "azurerm" {
  features {}
}

resource "tls_private_key" "hashidemos" {
  algorithm = "RSA"
}

data "azurerm_resource_group" "hashidemos" {
  name = var.prefix
}

resource "azurerm_virtual_network" "hashidemos" {
  name                = var.prefix
  location            = var.region["Azure"]
  resource_group_name = data.azurerm_resource_group.hashidemos.name
  tags                = local.common_tags
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = var.prefix
  resource_group_name  = data.azurerm_resource_group.hashidemos.name
  virtual_network_name = azurerm_virtual_network.hashidemos.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "hashidemos" {
  name                = "${var.prefix}-vault-ip"
  location            = var.region["Azure"]
  resource_group_name = data.azurerm_resource_group.hashidemos.name
  allocation_method   = "Dynamic"
  tags                = local.common_tags
}

resource "azurerm_network_security_group" "hashidemos" {
  name                = "${var.prefix}-nsg"
  location            = var.region["Azure"]
  resource_group_name = data.azurerm_resource_group.hashidemos.name
  tags                = local.common_tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "hashidemos" {
  name                = "${var.prefix}-nic"
  location            = var.region["Azure"]
  resource_group_name = data.azurerm_resource_group.hashidemos.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "${var.prefix}-nic"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.hashidemos.id
  }
}

resource "azurerm_network_interface_security_group_association" "hashidemos" {
  network_interface_id      = azurerm_network_interface.hashidemos.id
  network_security_group_id = azurerm_network_security_group.hashidemos.id
}

resource "azurerm_storage_account" "hashidemos" {
  name                     = "hashidemos"
  resource_group_name      = data.azurerm_resource_group.hashidemos.name
  location                 = var.region["Azure"]
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

data "azurerm_image" "packer" {
  name                = var.prefix
  resource_group_name = data.azurerm_resource_group.hashidemos.name
}

resource "azurerm_virtual_machine" "hashidemos" {
  name                          = "${var.prefix}-vm"
  location                      = var.region["Azure"]
  resource_group_name           = data.azurerm_resource_group.hashidemos.name
  network_interface_ids         = [azurerm_network_interface.hashidemos.id]
  vm_size                       = "Standard_B1s"
  delete_os_disk_on_termination = true
  tags                          = local.common_tags

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name              = "OsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    id = data.azurerm_image.packer.id
  }

  os_profile {
    computer_name  = "${var.prefix}-vm"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = tls_private_key.hashidemos.public_key_openssh
    }
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = azurerm_storage_account.hashidemos.primary_blob_endpoint
  }
}
