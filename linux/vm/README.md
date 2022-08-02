# Linux on Azure with Bicep/ARM and Virtual Machines (VM)

## Azure Portal

Use the following link to deploy the template in this repo using the Azure Portal:

[Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Flinux%2Fvm%2Fvm.json)

The above "Deploy to Azure" can be the fastest way to get up and running with no local dependencies. 

You can see how this link is generated in [PORTAL.md](PORTAL.md). It uses the [vm.json](vm.json) ARM (Azure Resource Manager) template, generated from the [vm.bicep](vm.bicep) Bicep template using the `az bicep build -f vm.bicep` command.

To deploy via the command line, which deploys the Bicep template directly, enables you to easily customize the it to your requirements, install the [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) and follow the steps below. These examples require a bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc).

## Cloud-init

This template uses [cloud-init](https://cloudinit.readthedocs.io/en/latest/), _the industry standard multi-distribution method for cross-platform cloud instance initialization_.

There are multiple pre-defined cloud-init templates included in `vm.bicep` which can be selected via the `cloudInit` parameter. These can help you create your own `cloud-init` scripts. We also include an `env` parameter that enables you to pass data to your `cloud-init` scripts in JSON format (default: `{}`).

The current pre-defined cloud-init options are:

### none

Do not run any cloud-init script (default). 

### docker

Installs [docker](https://docs.docker.com/engine/install/ubuntu/) for containers and [jq](https://stedolan.github.io/jq/) for working with JSON such as our `env` parameter. This is defined in the `packages` module of our cloud-init. We use `groups` and `system_info` to add the default user to the docker group. See variable `cloudInitDocker` in [vm.bicep](vm.bicep).

This template is used as the foundation for other templates such as `tailscale` and is an excellent starting point for your own cloud-init scripts.

### tailscale

This package uses the `write_files` and `run_cmd` modules to write the `env` parameter (`{"tskey":"..."}`) to `/home/azureuser/env.json` function), and our setup script to `/home/azureuser/tailscale.sh`. The `env` variable is embedded in the template using Bicep's [format](https://docs.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions-string#format) function. The `tskey` value is extracted using `jq` and the script completes by echoing the current date to `/home/azureuser/hello.txt`. See variable `cloudInitTailscale` in [vm.bicep](vm.bicep).

You must generate a Tailscale [Auth key](https://tailscale.com/kb/1085/auth-keys/) via <https://login.tailscale.com/admin/settings/keys> prior to running this script. We recommend using a **one-off** key for this purpose, especially if you are not using [device authorization](https://tailscale.com/kb/1099/device-authorization/).

### url

This is an example of running a simple bash script by its URL using `#include`. It is currently hard-coded to [cloud-init/cloud-init.sh](cloud-init/cloud-init.sh), but could easily be parameterized. See variable `cloudInitUrl` in [vm.bicep](vm.bicep).

## Resource Group 

```bash
RESOURCE_GROUP='220700-azure-linux'
LOCATION='eastus'

az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
```

## Virtual Machine (VM)

### basic

Deploy the template with default values.

```bash
RESOURCE_GROUP='220700-azure-linux'

az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep
```

This template includes defaults for all values including `allowIpPort22`, set to `127.0.0.1`, and a temporary default public SSH key for `adminPasswordOrKey`, which should be set to your own value in production. This allows the template to be deployed in a single click or CLI command.

### advanced

Set an SSH key using `adminPasswordOrKey` and open Port 22 (SSH) to your current IP using `allowIpPort22`.

```bash
RESOURCE_GROUP='220700-azure-linux'
PASSWORD_OR_KEY="$(cat ~/.ssh/id_rsa.pub)"
IP_ALLOW=$(dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"')

OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep \
    --parameters \
        adminPasswordOrKey="$PASSWORD_OR_KEY" \
        allowIpPort22="$IP_ALLOW")

echo $OUTPUT | jq -r '.properties.outputs.sshCommand.value'
```

### advanced

Create a VM with a custom name (e.g. `vm1` vs `vm2`) using `vmName`, which enables it to be deployed in the same Resource Group as a previous VM, select `tailscale` as the `cloudInit` option and pass in the `tskey` using `env`.

```bash
# first create a file _/env.json with vs code:
# code -r _/env.json
# with the following content:
# {"tskey":"..."}

RESOURCE_GROUP='220700-azure-linux'
VM_NAME='vm2'
ENV=$(cat _/env.json)
OUTPUT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file vm.bicep \
    --parameters \
        vmName="$VM_NAME" \
        cloudInit='tailscale' \
        env="$ENV")

echo $OUTPUT | jq -r '.properties.outputs.sshCommand.value'
```

## Delete Resources

When you are finished you may wish to empty the entire Resource Group, which can be done quickly be deploying an empty ARM template, [empty.json](empty.json). This leaves the Resource Group in place and ready for another deployment.

```bash
# empty resource group
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file empty.json \
    --mode Complete
```

Alternatively, you may wish to simply re-deploy a specific VM in the Resource Group when performing a task such as testing a cloud-init configuration. In this case you can delete the specific virtual machine and its disk (leaving other resources in place), and re-deploy the original template.

```bash
# delete single vm and disk for re-deployment
VM_NAME='vm2'
az vm delete --yes --resource-group $RESOURCE_GROUP --name $VM_NAME 
az disk delete --yes --resource-group $RESOURCE_GROUP --name "${VM_NAME}-osdisk1"
```
