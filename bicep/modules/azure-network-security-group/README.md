# azure-network-security-group

This module deploys a [Microsoft.Network/networkSecurityGroups](https://learn.microsoft.com/azure/templates/microsoft.network/networksecuritygroups?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |

## Outputs

| Name | Description |
|------|-------------|
| `id` | This is the id of the resource |
