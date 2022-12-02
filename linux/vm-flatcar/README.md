# Flatcar Linux on Azure

The example [Butane Config](https://flatcar-linux.org/docs/latest/installing/cloud/azure/#butane-config) at [cl.yaml](./cl.yaml) is from the [Running Flatcar Container Linux on Microsoft Azure](https://flatcar-linux.org/docs/latest/installing/cloud/azure/) in the Flatcar Linux documentation.

Transpile it to [ignition.json](./ignition.json).

```bash
cd linux/vm-flatcar
cat cl.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json
```

Set the `cloudInitIgnition` variable in [vm.bicep](./vm.bicep) to the contents of [ignition](./ignition.json). You can pretty-print the JSON via `jq` (e.g. `cat ignition.json | jq`) or an editor like VS Code.

## Azure Portal

Use the following link to deploy the template in this repo using the Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Flinux-flatcar%2Flinux%2Fvm-flatcar%2Fvm.json)

If you would like to deploy the Bicep template via the Azure CLI, explore the **Azure CLI** section below. To update the Deploy to Azure button with your own template, explore the **Azure Portal (continued)** section below.

## Azure CLI + Make

We will be using the Azure CLI and the [Makefile](./Makefile) to run `az group create`, and `az deployment group create` commands.

### group

Creates the [resource group](https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-cli#what-is-a-resource-group).

### deploy

Deploys [vm.bicep](./vm.bicep).

### empty

Emptys the resource group by deploying [empty.bicep](./empty.bicep) with `--mode Complete`.

### arm

Builds [vm.json](./vm.json) from [vm.bicep](./vm.bicep), which will be used for the portal deployment option above.

## Deploy

Run the following command to ensure the resource group exists, and is empty, and make a fresh deployment.

```bash
cd linux/vm-flatcar
make group empty deploy
```

## Azure Portal (continued)

```bash
# create vm.json
az bicep build -f vm.bicep

# create url
BRANCH_OR_COMMIT='linux-flatcar'
#BRANCH_OR_COMMIT=$(git rev-parse HEAD)
TEMPLATE_URL="https://raw.githubusercontent.com/Azure-Samples/azure-opensource-labs/${BRANCH_OR_COMMIT}/linux/vm-flatcar/vm.json"
OUTPUT_URL='https://portal.azure.com/#create/Microsoft.Template/uri/'$(printf "$TEMPLATE_URL" | jq -s -R -r @uri )
echo $OUTPUT_URL

# https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Flinux-flatcar%2Flinux%2Fvm-flatcar%2Fvm.json
```
