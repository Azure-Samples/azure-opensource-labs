# Explore Azure Linux Container Host for Azure Kubernetes Service (AKS) and GPU workloads

In this lab you will deploy an Azure Kubernetes Service (AKS) cluster with Azure Linux Container Host nodes, a GPU node pool, and other Azure services (Container Registry, Managed Identity, Storage Account), with the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview).

## Requirements

- An **Azure Subscription** (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
- The [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
- [Go](https://go.dev/dl/) (Optional)
- [Mage](https://magefile.org/) (`go install github.com/magefile/mage@latest`) (Optional)

## Instructions

Use the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) templates to deploy the infrastructure for your application.

Login to the Azure CLI.

```bash
az login
```

Clone this repository.

```bash
git clone https://github.com/Azure-Samples/azure-opensource-labs.git
```

Change to this directory.

```
cd azure-opensource-labs/cloud-native/aks-azure-linux
```

While you can deploy the Bicep templates ([aks.bicep](./aks.bicep)) via the Azure CLI or Azure Portal, we have included a Magefile, [magefile.go](./magefile.go), with the following targets to make deployment easier.

```
$ mage
Targets:
  aksCredentials    gets credentials for the AKS cluster
  aksKubectl        ensures kubectl is installed
  deployAKS         deploys aks.bicep at the Resource Group scope
  emptyNamespace    has az invoke kubectl delete all on K8S_NAMESPACE
  group:create      creates the Azure Resource Group
  group:delete      deletes the Azure Resource Group
  group:empty       empties the Azure Resource Group
```

### Deployment

```
mage group:create deployAks
```

### Delete resources

```
mage group:empty
```
