# Azure Kubernetes Service (AKS)

## Prerequisites

- Azure CLI
- Bicep
- Azure Subscription

## Deploy

Azure Linux V3 Preview feature registration:

```bash
az feature register \
    --namespace Microsoft.ContainerService \
    --name AzureLinuxV3Preview
```

```bash
az feature show \
    --namespace Microsoft.ContainerService \
    --name AzureLinuxV3Preview
```

```bash
az provider register \
    -n Microsoft.ContainerService
```

Create resource group:

```bash
az group create \
    --name 250100-aks \
    --location eastus
```

Deploy Azure Kubernetes Service (AKS) cluster:

```bash
az deployment group create \
    --resource-group 250100-aks \
    --template-file cloud-native/aks-arm/aks.bicep
```

## Cleanup

Deploy the empty Bicep template:

```bash
az deployment group create \
    --resource-group 250100-aks \
    --mode Complete \
    --template-file cloud-native/aks-arm/empty.bicep
```
