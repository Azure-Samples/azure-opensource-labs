# azure-kubernetes-service-addons

This module updates an AKS cluster to append add-ons. [`addonProfiles`](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters?pivots=deployment-language-bicep#managedclusterproperties) are not very well documented.

> This Bicep template will emit warnings due to the `mode: 'Incremental'` setting. This module still works and the warning messaging is being tracked here: https://github.com/Azure/bicep/issues/784

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `clusterId` | Existing cluster resource Id |  |
| `addonProfiles` | Add-ons to enable | Object? 🤔 No concrete definition so your best best is to deploy using Azure CLI or Portal and see what the JSON metadata looks like |

## Outputs

| Name | Description |
|------|-------------|
