# azure-kubernetes-service-ingress

This module updates an AKS cluster to install the `webAppRouting` add-on via `ingressProfile`. [`ingressProfiles`](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters?pivots=deployment-language-bicep#managedclusteringressprofile) requires a [`webAppRouting`](https://learn.microsoft.com/azure/templates/microsoft.containerservice/managedclusters?pivots=deployment-language-bicep#managedclusteringressprofilewebapprouting) object to enable the managed NGINX ingress controller in the cluster. This object accepts an optional `dnsZoneResourceId` to enable the `external-dns` controller.

> This Bicep template will emit warnings due to the `mode: 'Incremental'` setting. This module still works and the warning messaging is being tracked here: https://github.com/Azure/bicep/issues/784

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `location` | Region to deploy resource into | Azure region that offers this resource |
| `clusterId` | Existing cluster resource Id |  |
| `dnsZoneResourceId` | Azure DNS zone resource identifier | This is optional and not required for `webAppRouting` |

## Outputs

| Name | Description |
|------|-------------|
| N/A  |             |
