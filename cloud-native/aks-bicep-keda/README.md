# Explore KEDA (Kubernetes Event-driven Autoscaling) and the KEDA HTTP Add-on with Azure Kubernetes Service (AKS) and Bicep

In this lab you will deploy an Azure Kubernetes Service (AKS) cluster and other Azure services (Container Registry, Managed Identity, Storage Account, Service Bus, Key Vault), the open source KEDA (Kubernetes Event-driven Autoscaling) project with [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview).

## Requirements

- An **Azure Subscription** (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
- A [GitHub Account](https://github.com)

## 1. Setup

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
cd cloud-native/aks-bicep-keda/01-aks
bash deploy-main.sh
```

## 2. KEDA

Set environment variables.

```bash
RESOURCE_GROUP='220600-keda'
AKS_NAME='aks1'
```

Invoke kubectl command on AKS cluster.

```bash
cd ../02-keda/deploy

az aks command invoke \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --file . \
    --command 'kubectl apply -k .'
```

Authenticate local kubectl.

```bash
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --overwrite-existing 
```

Create secrets for Azure Blob Storage.

```bash
export AZURE_STORAGE_ACCOUNT_NAME="$(az storage account list -g $RESOURCE_GROUP --out tsv --query '[0].name')"

AZURE_STORAGE_PRIMARY_ACCOUNT_KEY=$(az storage account keys list \
    --account-name "$AZURE_STORAGE_ACCOUNT_NAME" \
    --out tsv \
    --query '[0].value')

AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string \
    -g $RESOURCE_GROUP \
    --name "$AZURE_STORAGE_ACCOUNT_NAME" \
    --out tsv \
    --query 'connectionString')

kubectl delete -k .

kubectl apply -k .

kubectl create secret generic az-storage-account \
    --namespace go-blob \
    --from-literal=AZURE_STORAGE_ACCOUNT_NAME="${AZURE_STORAGE_ACCOUNT_NAME}" \
    --from-literal=AZURE_STORAGE_PRIMARY_ACCOUNT_KEY="${AZURE_STORAGE_PRIMARY_ACCOUNT_KEY}" \
    --from-literal=AZURE_STORAGE_CONNECTION_STRING="${AZURE_STORAGE_CONNECTION_STRING}"
```

## 3. KEDA HTTP Add-on

Follow the steps in [03-keda-http](./03-keda-http/) to install the [HTTP Add-on](https://github.com/kedacore/http-add-on) and deploy the [asw101/go-hello](https://github.com/asw101/go-hello) application to it.
