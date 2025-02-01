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

## Deploy via Azure Portal

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Fcloud-native%2Faks-arm%2Faks.json)
