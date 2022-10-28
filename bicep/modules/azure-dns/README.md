# azure-dns-zone

This module deploys a [Microsoft.Network/dnsZones](https://learn.microsoft.com/azure/templates/microsoft.network/dnszones?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `zoneType` | Zone type | `'Public'`</br>`'Private'` |

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource identifier |
