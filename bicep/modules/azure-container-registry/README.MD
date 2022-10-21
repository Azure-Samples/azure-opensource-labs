# azure-container-registry

This module deploys a [Microsoft.ContainerRegistry/registries](https://learn.microsoft.com/azure/templates/microsoft.containerregistry/registries?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `sku` | SKU to deploy | `'Basic'` <br/> `'Standard'` <br/> `'Premium'`
| `managedIdentityType` | Managed identity type to assign on the resource | `'SystemAssigned'`<br/>`'UserAssigned'` |
| `userAssignedIdentities` | List of user assigned identity resource IDs to assign to the resource when the managed identity type is set to `UserAssigned` | Array of resource IDs |
| `adminUserEnabled` | Enables the admin account | `true` or `false` |
| `anonymousPullEnabled` | Enables anonymous pull access | `true` or `false` |
| `publicNetworkAccess` | Enables public network access | `true` or `false` |

## Outputs

| Name | Description |
|------|-------------|
| `name` | This is the name of the resource |
