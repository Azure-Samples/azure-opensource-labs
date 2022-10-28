# azure-log-analytics-workspace

This module deploys a [Microsoft.OperationalInsights/workspaces](https://learn.microsoft.com/azure/templates/microsoft.operationalinsights/workspaces?pivots=deployment-language-bicep) resource.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |

## Outputs

| Name | Description |
|------|-------------|
| `id` | This is the id of the virtual network resource |
