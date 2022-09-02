output "ingress_url" {
  value = format("%s%s", "https://", jsondecode(azapi_resource.helloworld.output).properties.configuration.ingress.fqdn)
}

output "resource_group_id" {
  value = azurerm_resource_group.aca.id
}