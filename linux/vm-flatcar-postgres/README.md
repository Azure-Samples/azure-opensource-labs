# Linux on Azure with Flatcar Linux and Azure Database for PostgreSQL

```
$ mage
Targets:
  acceptTerms          accepts the Flatcar VM image terms
  bicep                injects ignition.json into the customDataIgnition variable in vm.bicep
  butane               uses the Butane CLI tool to generate ignition.json from cl.yaml
  clean                removes files created during deployment
  configurePostgres    configures ad-admin user and firewall rule
  deployMain           deploys main.bicep at the Subscription level
  deployPostgres       deploys postgres.bicep to the Azure resource group
  deployVM             deploys vm.bicep to the Azure resource group with parameters
  empty                empties the Azure resource group
  ensureButane         downloads butane from GitHub (coreos/butane/releases)
  env                  prints the sample environment variables
  group                creates the Azure resource group
  groupDelete          deletes the Azure resource group
  password             prints a securely generated password to the standard output
  psqlCommand          outputs the psql command
  psqlDocker           connect via pql using docker and the latest postgres image
  sshCommand           outputs the SSH command
  tailscaleDeploy      runs tailscale on the VM via docker
  tailscaleLogs        get the logs for the tailscale container
```

## Usage

The below commands create a resoure group, empty it, deploy the VM and Postgres, and configure Postgres.

```
export SSH_KEY=~/.ssh/id_rsa.pub
mage group empty deployVm deployPostgres configurePostgres
```
