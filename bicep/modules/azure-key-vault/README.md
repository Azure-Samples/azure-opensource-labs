# azure-key-vault

This module deploys a [Microsoft.KeyVault/vaults](https://learn.microsoft.com/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep) resource using only parameters scoped for these labs. The deployment will set initial access policy for the user that runs the Bicep template and also accepts an array of `resourceAccessPolicies` for additional policy assignments.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `sku` | Resource SKU | `premium` or `standard` (default) |
| `userObjectId` | The user object Id to give full-access to | This is typically the identity that runs the template |
| `tenantId` | The tenant which the objectIds belong to for access policy assignments | |
| `accessPolicies` | Array of `accessPolicy` objects | See: [AccessPolicyEntry](https://learn.microsoft.com/azure/templates/microsoft.keyvault/vaults?pivots=deployment-language-bicep#accesspolicyentry) |

## Outputs

| Name | Description |
|------|-------------|
