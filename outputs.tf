output "vm_public_ip" {
  value = data.azurerm_public_ip.pip.ip_address
}

output "nginx_url" {
  value = "http://${data.azurerm_public_ip.pip.ip_address}"
}
