# azure-cli-script

This module deploys a [Microsoft.Resources/deploymentScripts](https://learn.microsoft.com/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep) resource to run Azure CLI commands as part of your deployment. The deployment will create a User-Assigned Managed Identity and it will be granted Contributor permissions to perform actions within your subscription.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `azCliVersion` | Azure CLI version | Usually supports latest-1 |
| `cleanupPreference` | Indicates when to cleanup Azure Container Instance  | Defaults to `OnSuccess` |
| `scriptContent` | Inline Azure CLI script | |

## Outputs

| Name | Description |
|------|-------------|
| N/A  |             |
