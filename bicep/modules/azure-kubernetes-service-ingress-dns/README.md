# azure-kubernetes-service-ingress-dns

**Work in Progress**

This module will take the `principalId` of the `webapprouting` managed identity resource and assign the "DNS Zone Contributor" to it at the Azure DNS resource scope.

> This Bicep template will emit warnings due to the `mode: 'Incremental'` setting. This module still works and the warning messaging is being tracked here: https://github.com/Azure/bicep/issues/784

## Inputs

| Name | Description | Expected Value |
|------|-------------|----------------|
| `dnsZoneName` | The DNS zone name used to pull the existing resource for RBAC assignment |
| `principalId` | The principal id of the user-assigned managed identity that is provisioned in the AKS managed cluster resource group (starts with `MC_*`) |  |

## Outputs

| Name | Description |
|------|-------------|
| N/A  |             |
