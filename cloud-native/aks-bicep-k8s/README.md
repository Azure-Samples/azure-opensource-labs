# Explore Open Source workloads with Azure Kubernetes Service (AKS) and the Bicep extensibility Kubernetes provider

In this lab you will deploy an Azure Kubernetes Service (AKS) cluster, other Azure services (Container Registry, Managed Identity, Storage Account), and open source workloads, with [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli), [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) and the [Bicep extensibility Kubernetes provider (Preview)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-extensibility-kubernetes-provider).

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
cd azure-opensource-labs/cloud-native/aks-bicep-k8s
```

While you can deploy the Bicep templates ([main.bicep](./main.bicep)) via the Azure CLI or Azure Portal, we have included a Magefile, [magefile.go](./magefile.go), with the following targets to make deployment easier.

```
$ mage
Targets:
  aksCredentials    gets credentials for the AKS cluster
  aksKubectl        ensures kubectl is installed
  deployAKS         deploys aks.bicep at the Resource Group scope
  deployApp         DeployAKS uses aks-deploy-app.bicep to deploy AKS_APP_BICEP(=azure-vote.bicep)
  deployMain        [experimental] deploys main.bicep::q at the Resource Group scope
  empty             empties the Azure resource group
  emptyNamespace    has az invoke kubectl delete all on K8S_NAMESPACE
  group             creates the Azure resource group
  groupDelete       deletes the Azure resource group
```

### Deployment

```
mage group deployAks deployApp
```

### Delete resources

```
mage empty
```
