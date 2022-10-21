# azure-kubernetes-service-nodepools

This module deploys a [Microsoft.ContainerService/managedClusters/agentPools](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters/agentpools?pivots=deployment-language-bicep) resource using only parameters scoped for these labs.

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `name` | This is the name of the resource | Whatever you want |
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `tags` | Tags | Object of key/value pairs |
| `managedClusterName` | Name of the AKS resource | Resource name |
| `userNodes` | Array of userNode objects. This is a dynamic object so parameter names will not always match up with template specifications. The Bicep code will iterate through each userNode object and deploy into your AKS resource. | Array of objects |

## Outputs

| Name | Description |
|------|-------------|
| N/A  |             |
