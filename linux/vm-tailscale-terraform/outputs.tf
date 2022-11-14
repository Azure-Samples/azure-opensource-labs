# output "tls_private_key" {
#   value     = tls_private_key.kube.private_key_pem
#   sensitive = true
# }

output "ssh_command" {
  value = "ssh ${var.vm_username}@${azurerm_linux_virtual_machine.ts.name}"
}
