# Explore KEDA (Kubernetes Event-driven Autoscaling) on Azure Kubernetes Service (AKS)

In this lab you will deploy an Azure Kubernetes Service (AKS) cluster and other Azure services (Container Registry, Managed Identity, Storage Account, Service Bus, Key Vault), the open source KEDA (Kubernetes Event-driven Autoscaling) project with [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview).

## Requirements

- An **Azure Subscription** (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
- A [GitHub Account](https://github.com)

## Instructions

Use the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) templates to deploy the infrastructure for your application.

Login to the Azure CLI.

```bash
az login
```

Install kubectl using the Azure CLI, if required.

```bash
az aks install-cli
```

Deploy the Bicep template for your Azure Kubernetes Service (AKS) cluster.

```bash
cd cloud-native/aks-bicep/01-aks
bash deploy-main.sh
```

Invoke kubectl command on AKS cluster.

```bash
RESOURCE_GROUP='220600-keda'
AKS_NAME='aks1'

az aks command invoke \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --command 'kubectl run nginx --image=nginx'
```
