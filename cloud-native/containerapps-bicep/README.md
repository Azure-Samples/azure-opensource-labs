# Explore Azure Container Apps, Bicep, and PostgreSQL

In this lab you will deploy Azure Container Apps, Azure Database for PostgreSQL, and other Azure Services (Key Vault, Storage and Managed Identity) with [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/overview).

You will deploy containers from GitHub [Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) and built with GitHub [Actions](https://docs.github.com/en/actions/publishing-packages/publishing-docker-images#publishing-images-to-github-packages).

You will also import and have the opportunity to explore data from the [Cassini](https://en.wikipedia.org/wiki/Cassini%E2%80%93Huygens) mission to Saturn, thanks to Rob Conery ([@robconery](https://twitter.com/robconery))'s [A curious moon](https://bigmachine.io/products/a-curious-moon/)/[SQL in Orbit](https://bigmachine.io/product/sql-in-orbit/).

## Requirements

- An **Azure Subscription** (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
- The [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
- A [GitHub Account](https://github.com)

## Instructions

Use the [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) and [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/overview) templates to deploy the infrastructure for your application.

Login to the Azure CLI.

```bash
az login
```

Set environment variables and create a Resource Group.

```bash
RESOURCE_GROUP="my-container-apps"
LOCATION="canadacentral"

az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"
```

Change directory to this directory, `cloud-native/containerapps-bicep`.

```bash
cd cloud-native/containerapps-bicep
```

Deploy the bicep templates of your choice with the following `az deployment` commands.

```bash
# containerapp
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./containerapp.bicep \
  --parameters \
      location="$LOCATION"

# storage
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./storage.bicep

# postgres + keyvault (combined)
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./postgres-keyvault.bicep

# key vault (stand-alone)
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./keyvault.bicep

# postgres (stand-alone)
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./postgres.bicep

# empty
az deployment group create \
  --mode Complete \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ./empty.bicep
```

See [POSTGRES.md](POSTGRES.md) for instructions on how to login to your Postgres server from your local machine.

Once you have finished exploring, you should delete the resource group to avoid any further charges.

```bash
az group delete \
  --name $RESOURCE_GROUP
```
