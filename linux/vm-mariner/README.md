# Linux on Azure with CBL-Mariner Linux 2.0 and Virtual Machines (VM)

NOTE: This lab is for experimentation with the open source [CBL-Mariner](https://github.com/microsoft/CBL-Mariner) project, and **not a currently supported offering** for Virtual Machines on Azure. For the fully-supported Azure Linux offering for AKS, see [Introducing the Azure Linux container host for AKS](https://aka.ms/azure-linux) and [Quickstart: Deploy an Azure Linux Container Host for AKS cluster by using the Azure CLI](https://learn.microsoft.com/azure/azure-linux/quickstart-azure-cli).

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Flinux%2Fvm-mariner%2Fvm.json)

```
$ mage
Targets:
  dockerTailcale     installs Docker and runs Tailscale on the VM
  group:create       creates the Azure Resource Group
  group:delete       deletes the Azure Resource Group
  group:empty        empties the Azure Resource Group
  managedIdentity    creates a managed identity for the Azure VM
  pg                 creates the Azure Database for Postgres via the CLI (az postgres flexible-server create)
  pgAdmin            adds the Managed Identity as Postgres server admin
  runScript          runs an optional command (VM_COMMAND) followed by script (VM_SCRIPT) using RunCommand on the Azure VM
  ssh                gets the FQDN of the VM and outputs an ssh command
  sshKey             creates an ssh key for Azure VMs
  subscription       switches between two Azure subscriptions
  vm                 creates the Azure VM via the CLI (az vm create)
  vmBicep            deploys vm.bicep to the Azure resource group with parameters
```
