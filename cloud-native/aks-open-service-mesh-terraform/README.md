# Azure Kubernetes Service with Open Service Mesh and Terraform

This directory holds Terraform configuration files for deploying an AKS cluster with the Open Service Mesh add-on enabled. It is an alternative to [deploying with Azure Bicep](../aks-open-service-mesh#deploy-azure-resources)

## Requirements

- An **Azure Subscription** (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
- The [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
- The [Terraform CLI](https://www.terraform.io/downloads)

## Deploy Azure Resources using Terraform

Terraform will use your Azure CLI login context to deploy the resources into your subscription. 

Login to the Azure CLI.

```bash
az login
```

Optionally set the correct subscription if you have more than one. You can list them via `az account list`.

```bash
az account set -s '<YOUR_SUBSCRIPTION_NAME>'
```

Change to the `cloud-native/aks-open-service-mesh-terraform` subdirectory of this repo and run the Terraform deployment script.

```bash
cd cloud-native/aks-open-service-mesh-terraform
terraform init
terraform apply
```

> [Terraform state](https://www.terraform.io/language/state) files will be stored locally within your current directory; however, best practice is to store your Terraform state files in [Azure Storage](https://learn.microsoft.com/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli) or [Terraform Cloud](https://cloud.hashicorp.com/products/terraform).

## Validate the deployment

Once you've completed the deployment of Azure infrastructure, run the following command to set the random deployment name to an environment variable.

```bash
export name=$(terraform output -raw random_pet_name)
```

Authenticate `kubectl` against the AKS cluster with the following command.

```bash
az aks get-credentials \
    --resource-group "rg-${name}" \
    --name "aks-${name}"
```

Validate access to your AKS cluster using `kubectl`.

```bash
kubectl get nodes -o wide
```

## Next steps

Continue on to the [Validate OSM resources and configurations](../aks-open-service-mesh#validate-osm-resources-and-configurations) portion of the [Azure Kubernetes Service with Open Service Mesh](../aks-open-service-mesh/) lab to deploy workloads to your cluster.

> NOTE: In your terminal you should perform `cd ../aks-open-service-mesh` to be in the proper directory to complete the rest of the lab.

## Clean up resources

Once you have finished exploring Azure Kubernetes Service with Open Service Mesh and Terraform, you should delete the deployment to avoid any further charges.

Run the `destroy` command to delete all your resources.

```bash
terraform destroy
```
