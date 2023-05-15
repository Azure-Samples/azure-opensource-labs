# Linux on Azure with CBL-Mariner Linux 2.0 and Virtual Machines (VM)

```
$ mage
Targets:
  dockerTailcale     installs Docker and runs Tailscale on the VM
  group:create       creates the Azure Resource Group
  group:delete       deletes the Azure Resource Group
  group:empty        empties the Azure Resource Group
  managedIdentity    creates a managed identity for the Azure VM
  runScript          runs an optional command (VM_COMMAND) followed by script (VM_SCRIPT) using RunCommand on the Azure VM
  ssh                gets the FQDN of the VM and outputs an ssh command
  sshKey             creates an ssh key for Azure VMs
  subscription       switches between two Azure subscriptions
  vm                 creates the Azure VM via the CLI (az vm create)
  vmBicep            deploys vm.bicep to the Azure resource group with parameters
```
