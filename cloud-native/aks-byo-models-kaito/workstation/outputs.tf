output "public_ip" {
  value = azurerm_public_ip.example.ip_address
}

output "ssh_username" {
  value = var.vm_username
}

output "ssh_private_key" {
  value = local_file.ssh_private_key.filename
}