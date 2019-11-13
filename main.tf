# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "assareh-demo"
    location = "westus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "assareh-demo-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "westus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "westus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}
# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "westus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
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

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "westus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "westus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "westus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOaM3FdYELWhmEx9+Ab16KVQFL2zlW06EPMogjgotLAoutW7XkgS3cgaoXuy4DhF2XndEStCHEVjJxH1pMGV3Uy7hQpVzK6rh2DPM83FwbICbO+T096ydQ3YCKIdueR7KnP5aPb9aStYJvySTIsJT9BhBunIasbT2+K5/utDEfY/WxGxqw2gZKEBgE1hZPZZqF4Ib8GsY0llIbLKylFwucZQyR1lmeIiqkv03zOpkzozFm7zLMqO9vMIvUZ3mzA573UFitXkKZmRwQjGQ0sL4ajJPFE0V7cyoJ3ojSWGJ2dDh/obO2Lf3LD9roDoAfoCKMAFXrSVMjiRcskkVbfD2GH8YnVXnqJ+kRFuVd/hjK36Ck8oa/umhJRlnYVC477JXPhHczDHiDDtW23juljblwZD9/W9zu6uusv0mlHz3HGFiqlF8jGG5m2sV8wMlUBtQWNhk3Xk6kPopbWrpbaBVTKYLLYf8NydU7Pns3cLkV1YAKclwDPiXwtNPmDi0mMoW89u6hi0TShI29Xnfb9MWW+0EP0d6MAtyOQYDPq35jfSOaL0Qm9oUvMrcqmyTmJOl2f0yGayzmi5tEzXflwXpQz2KRz9y4Vx2Or2GiwkGfUWVjQ+HoHwnSplE3FvJis/r6r+FJM+nCb684+pTZs1D/nyZnD0bEG6/jR2goO2rJdQ== assareh@hashicorp.com"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}