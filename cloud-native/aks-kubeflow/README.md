# Kubeflow on Azure Kubernetes Service (AKS)

This lab the Advanced scenario for deployment of Kubeflow using [Mage](https://github.com/magefile/mage) and the included [magefile.go](magefile.go) for automation of deployment steps. See [BASIC-CLI.md](BASIC-CLI.md) for the Basic scenario which provides manual steps without any further automation, configuration of ingress, TLS, and stronger default password.

## Requirements

- [Go](https://go.dev/dl/)
- [Mage](https://magefile.org/) (`go install github.com/magefile/mage@latest`)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)

## Commands

```
$ mage
Targets:
  aks                creates the Azure Kubernetes Service (AKS) cluster
  aksCredentials     gets credentials for the AKS cluster
  aksKubectl         ensures kubectl is installed
  checkout           checks out the git repo to overwrite changes
  clean              cleans up the cloned folder
  clone              clones the kubeflow/manifests at the correct version
  configureDex       updates the manifests prior to deployment
  configureTLS       deploys the certificate manifest
  empty              empties the Azure resource group
  ensureKustomize    downloads kustomize from GitHub
  group              creates the Azure resource group
  groupDelete        deletes the Azure resource group
  kubectlReady       checks that all pods are ready
  kubeflow           installs kubeflow from the manifests
  kubeflowAll        runs clean clone configuredex patch kubeflow kubectlready restartdex configuretls
  kubeflowDelete     deletes kubeflow from the manifests
  kubeflowPods       returns all Kubeflow pods
  kubeflowPort       port forwards to Kubeflow
  password           generates a password and hash and outputs it to the standard output
  patch              copies manifests from aks/manifests/ to manifests/
  restartDex         restarts dex
  wait               for the specified number of seconds
```

## Deployment

```bash
# confirm tools
sudo mage ensurekustomize akskubectl

# kubernetes
mage group aks akscredentials

# kubeflow
mage kubeflowall
# or
mage clean clone configuredex patch kubeflow kubectlready restartdex configuretls
```
