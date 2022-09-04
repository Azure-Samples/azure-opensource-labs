resource "azurerm_servicebus_namespace" "aca" {
  name                = "sb-${local.resource_name_unique}"
  location            = azurerm_resource_group.aca.location
  resource_group_name = azurerm_resource_group.aca.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "aca" {
  name         = "myqueue"
  namespace_id = azurerm_servicebus_namespace.aca.id
}
