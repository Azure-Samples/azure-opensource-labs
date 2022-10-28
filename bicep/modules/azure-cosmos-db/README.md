# azure-cosmos-db

This module deploys a [Microsoft.DocumentDB/databaseAccounts](https://learn.microsoft.com/en-us/azure/templates/microsoft.documentdb/databaseaccounts?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `kind` | Type of database account | `'GlobalDocumentDB'`</br>`'MongoDB'` (default)</br>`'Parse'` |
| `mongoApiVersion` | MongoApi version | `'3.2'`</br>`'3.6'`</br>`'4.0'`</br>`'4.2'` (default) |
| `managedIdentityType` | Managed identity type to assign on the resource | `'SystemAssigned'`<br/>`'UserAssigned'` |
| `locations` | Array of geo-replication location objects | See: [locations](https://learn.microsoft.com/azure/templates/microsoft.documentdb/databaseaccounts?pivots=deployment-language-bicep#location) |
| `userAssignedIdentities` | List of user assigned identity resource IDs to assign to the resource when the managed identity type is set to `UserAssigned` | Array of resource IDs |

## Outputs

| Name | Description |
|------|-------------|
