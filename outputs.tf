// Azure
output "azure-instance-http-ip" {
  value = <<HTTP
    Connect to your virtual machine via HTTP:
    "http://${azurerm_public_ip.hashidemos.ip_address}"
HTTP
}

output "azure-instance-ssh-ip" {
  value = <<SSH
    Connect to your virtual machine via SSH:
    $ ssh -i assareh-hashidemos.pem -o IdentitiesOnly=yes ubuntu@${azurerm_public_ip.hashidemos.ip_address}
SSH
}

output "azure-instance-private-ip" {
  value = azurerm_network_interface.hashidemos.private_ip_address
}