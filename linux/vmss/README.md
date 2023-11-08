# Linux on Azure with Bicep/ARM and Virtual Machine Scale Sets (VMSS)

## Requirements

- [Go](https://go.dev/dl/)
- [Mage](https://magefile.org/) (`go install github.com/magefile/mage@latest`)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)

## Commands

```
$ mage
Targets:
  az:vmss         deploys vm.bicep
  group:create    creates the Azure Resource Group
  group:delete    deletes the Azure Resource Group
  group:empty     empties the Azure Resource Group
  test:whoAmI 
```

## Usage

```bash
# (optional) define the resource group name
# export RESOURCE_GROUP='231000-azr'

# create the group and deploy the vmss
mage group:create az:vmss

# tear down and/or delete
mage group:empty group:delete
```
