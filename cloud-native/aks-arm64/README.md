# Azure Kubernetes Service with ARM64 node pools

This lab will walk you though deploying Azure Kubernetes Service (AKS) with ARM64-based user node pools and deploy a sample application to it.

You will perform the following tasks:

* Provision Azure resources
* Build and publish ARM64-based container to Azure Container Registry
* Deploy ARM64-based image to Azure Kubernetes Service

As part of the application deployment process, we'll also explore some things you can do to ensure your container images are prepared for ARM64-based OS architecture.

## Requirements

* An Azure Subscription (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
* The [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
* A [GitHub](https://github.com/) account
* The [GitHub CLI](https://cli.github.com/)
* Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
* The [Docker CLI](https://www.docker.com/products/docker-desktop/)

## Deploy Azure Resources

Start by cloning this repo and navigating to the `cloud-native/aks-arm64` directory.

```bash
git clone https://github.com/Azure-Samples/azure-opensource-labs.git
cd azure-opensource-labs/cloud-native/aks-arm64 
```

Next, make sure you are logged into Azure CLI

```bash
az login
```

If you have access to multiple subscriptions, you can select the proper subscription to use with the following command:

```bash
az account set -s <YOUR_SUBSCRIPTION_NAME_OR_GUID>
```

> **⚠️ NOTE**
>
> You will need proper permissions in your subscription as the AKS deployment will require granting the `AcrPull` permissions to the `kubelets` on the AKS cluster, so that images can be pulled from your Azure Container Registry.

Prepare for deployment by setting a few environment variables. You will need to pass in a `location` (aka Azure region) that [supports your deployment resources](https://azure.microsoft.com/explore/global-infrastructure/products-by-region/?products=container-registry,kubernetes-service) and SKUs as well as a `name` for your resource deployments.

> **💡 TIP**
>
> To validate that a VM SKU is available in your preferred Azure region you can run a command like this:
>
> az vm list-sizes --location $location --query "[? contains(name, 'Standard_Dpds_v5')]" -o table`

The `name` variable will be used to name Azure resources. The naming convention used wil be adopted from this [guide](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming#example-names-general). Some resources have specific requirements around resource naming so it is generally safe to use shorter alphanumeric names and ensure they will be globally unique since ACR names must meet this criteria.

Set up your `location` and `name` variables.

```bash
location=eastus
name=arm$RANDOM
```

Run the Bicep template deployment using the following command:

```bash
az deployment sub create --name "$name-deploy" --location $location -f ./main.bicep --parameters name=$name location=$location
```

The deployment of Azure resources can take up to 10 minutes to complete. If you are interested in learning how the Bicep template modules work, click the `show` link below.

<details><summary>show</summary>

The [main.bicep](./main.bicep) file deploys the following resources in your subscription:

* Azure Resource Group
* Azure Container Registry
* Azure Kubernetes Cluster with system node pool
* ARM64-based user node pool with SKU (`Standard_D4pds_v5`)

The template leverages Bicep modules which have been published to a separate ACR (`cloudnativeadvocates.azurecr.io`). To avoid having to include the ACR server name in all module calls, the ACR server name has been aliased in the [bicepconfig.json](./bicepconfig.json) file.

The code for each Bicep module is hosted in this repo in the [bicep/modules](/bicep/modules/) directory. There you will find subdirectories for each of the modules we use for this lab's deployment.

Within each module's subdirectory, there is a `README.md` file with additional information on the inputs and outputs for each module including links to the [resource template](https://learn.microsoft.com/azure/templates/) documentation.

Here's a quick summary of the resources being deployed

### Azure Resource Group

This deployment is at subscription scope, so we create a resource group in the `main.bicep` file to deploy all resources for this lab.

### Azure Container Registry

Uses `br/oss-labs:bicep/modules/azure-container-registry:v0.1` module to deploy a private container registry in which we will publish our sample container image to.

This ACR resource will have the admin account enabled to be able to publish container images using GitHub Actions.

### Azure Kubernetes Cluster with system node pool

Uses `br/oss-labs:bicep/modules/azure-kubernetes-service:v0.1` to deploy a managed cluster with Kubernetes version `1.24.3`. Some of the basic options have been enabled such as using a standard load balancer for inbound services and outbound NAT. The system node pool will use the `Standard_D2s_v5` Virtual Machine Scale Set SKU and deploy `2` instances.

AKS clusters can be provisioned with Defender enabled; however, at the time of this writing, ARM64-based node pools are not supported when AKS clusters have Defender enabled.

This AKS cluster will also have the ACR "attached" by granting the `kubelet` managed identity the `AcrPull` role assignment on the ACR resource.

### ARM64-based user node pool with SKU (`Standard_D4pds_v5`)

Uses `br/oss-labs:bicep/modules/azure-kubernetes-service-nodepools:v0.1` module to deploy a 2-node ARM64-based node pool with SKU `Standard_D4pds_v5`. This module accepts `userNodes` which is an array of dynamic objects. Each of the dynamic object properties are mapped to Bicep template properties in the module implementation.

With the node pool type of `VirtualMachineScaleSets`, we can enable autoscaling. You can specify the scale down mode to either `Deallocate` or `Delete`. This lab sets it to `Deallocate` to ensure faster scale up/down times; therefore, the `osDiskType` setting must be set to `Managed` so that Azure persists the OS disks. 

> The default `osDiskType` is `Ephemeral`

This user node pool will auto scale from `0` to `3` instances based on load

If you want to ensure only specific workloads are scheduled on your user node pools, you can add `nodeTaints`. Refer to this [doc](https://learn.microsoft.com/azure/aks/use-multiple-node-pools#setting-nodepool-taints) for additional information.
</p>
</details>

Once the deployment has completed, you can run the following command to gain access to the cluster:

```bash
az aks get-credentials --resource-group "rg-${name}" --name "aks-${name}"
```

To verify the cluster is up, run the command `kubectl get nodes -o wide` and should see something like this

```bash
kubectl get nodes -o wide
NAME                             STATUS     ROLES   AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-arm64-10552501-vmss000000    NotReady   agent   139m   v1.24.3   10.21.0.62    <none>        Ubuntu 22.04.1 LTS   5.15.0-1019-azure   containerd://1.6.4+azure-4
aks-arm64-10552501-vmss000001    NotReady   agent   139m   v1.24.3   10.21.0.91    <none>        Ubuntu 22.04.1 LTS   5.15.0-1019-azure   containerd://1.6.4+azure-4
aks-arm64-10552501-vmss000002    NotReady   agent   139m   v1.24.3   10.21.0.120   <none>        Ubuntu 22.04.1 LTS   5.15.0-1019-azure   containerd://1.6.4+azure-4
aks-system-23779925-vmss000000   Ready      agent   143m   v1.24.3   10.21.0.4     <none>        Ubuntu 18.04.6 LTS   5.4.0-1090-azure    containerd://1.6.4+azure-4
aks-system-23779925-vmss000001   Ready      agent   143m   v1.24.3   10.21.0.33    <none>        Ubuntu 18.04.6 LTS   5.4.0-1090-azure    containerd://1.6.4+azure-4
```

> 💡 TIP
>
> If you do not have `kubectl` installed on your system, you can run the following command to install it:
>
> `az aks install-cli`

## Deploying `ARM64` workloads to Kubernetes

With the ARM64-based user node pool deployed, we can begin deploying our first workload onto it.

We will deploy the famous [Azure Voting App](https://learn.microsoft.com/azure/aks/tutorial-kubernetes-prepare-app) which can be found in many AKS tutorials, labs, blogs, etc.

![Azure Voting App](https://learn.microsoft.com/en-us/azure/aks/media/container-service-kubernetes-tutorials/azure-vote-local.png)

This application is a multi-container application and upon inspection of the [`docker-compose.yaml`](https://github.com/Azure-Samples/azure-voting-app-redis/blob/master/docker-compose.yaml) file, we can see it uses the `mcr.microsoft.com/oss/bitnami/redis:6.0.8` image for the backend and the `mcr.microsoft.com/azuredocs/azure-vote-front:v1` for the frontend.

In order for Kubernetes to schedule containers to your ARM64-based node pool, the container images must be published to support the appropriate OS architectures.

### Investigation

You can inspect the container manifests by running the following commands:

```bash
docker manifest inspect mcr.microsoft.com/azuredocs/azure-vote-front:v1
docker manifest inspect mcr.microsoft.com/oss/bitnami/redis:6.0.8
```

Unfortunately, neither of these images support `arm64` architecture 😞

Let's check if Redis has an updated image on Docker Hub that supports `arm64`

```bash
docker manifest inspect redis:latest
```

From the output, we can see it does 🥳

```json
...
{
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "size": 1572,
    "digest": "sha256:6444b125d6e2b7aae5732039a22bf4abb92bcb1535cefe89e52bb269f6374826",
    "platform": {
      "architecture": "arm64",
      "os": "linux",
      "variant": "v8"
    }
}
...
```

Easy enough, we can swap out `mcr.microsoft.com/oss/bitnami/redis:6.0.8` with `redis:latest` and fix that dependency 😅

Now, browse to the [source repo](https://github.com/Azure-Samples/azure-voting-app-redis) for the Azure Voting App and view the [Dockerfile](https://github.com/Azure-Samples/azure-voting-app-redis/blob/master/azure-vote/Dockerfile) to see how the image is built.

From the Dockerfile, we can see it is using `tiangolo/uwsgi-nginx-flask:python3.6` as a base image.

If we run the `docker manifest inspect` command again, we can see the base image also doesn't support `arm64` architecture 😞

```bash
docker manifest inspect tiangolo/uwsgi-nginx-flask:python3.6
```

On Docker Hub, we can see the [tiangolo/uwsgi-nginx-flask](https://hub.docker.com/r/tiangolo/uwsgi-nginx-flask) image is built using this [this Dockerfile](https://github.com/tiangolo/uwsgi-nginx-flask-docker/blob/master/docker-images/python3.6.dockerfile)

Upon inspection of the Dockerfile, you can see this image sources from yet another base image called `tiangolo/uwsgi-nginx:python3.6`

Back in Docker Hub, we can view information for the [tiangolo/uwsgi-nginx](https://hub.docker.com/r/tiangolo/uwsgi-nginx) image. Here we see [this Dockerfile](https://github.com/tiangolo/uwsgi-nginx-docker/blob/master/docker-images/python3.6.dockerfile) is used to build the base image.

In the Dockerfile, we see it's base image is `python:3.6-buster`

This image is also hosted on Docker Hub so we can check to see if this image supports `arm64`

```bash
docker manifest inspect python:3.6-buster
```

In the output, we can see it supports many architectures including `arm64` 🥳

```json
...
{
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "size": 2217,
    "digest": "sha256:293f12079921200fb3b9d17996bb0a06d743828d2bdd7eb49e245aee26d2f802",
    "platform": {
      "architecture": "arm64",
      "os": "linux",
      "variant": "v8"
    }
}
...
```

The existing [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis/blob/master/azure-vote/Dockerfile) container image will not work for us, we must build and publish our own container and have it support multiple OS architectures. Thankfully, we can borrow a lot of [tiangolo's](https://github.com/tiangolo) code and build our own custom Dockerfile from it.

With the focus of this lab being on deploying `arm64` workloads to AKS, we've saved you some time and combined the container image code from the original [Azure Voting App](https://github.com/Azure-Samples/azure-voting-app-redis) repo and [tiangolo's](https://github.com/tiangolo) Dockerfiles and published a new Azure Voting App repo [here](https://github.com/pauldotyu/azure-voting-app/blob/main/src/Dockerfile). This repo supports both AMD64 and ARM64 OS architectures by building and pushing images using [`docker buildx`](https://docs.docker.com/engine/reference/commandline/buildx/).

### Deploying the Azure Voting App

#### Build and publish the container image

Navigate to the updated [Azure Voting App](https://github.com/pauldotyu/azure-voting-app) repo and click on the green "Use this template" button. This will allow you to create a new repo in your GitHub account.

With the repo created in your GitHub account, clone the repo and open it in a terminal.

This repo contains a [GitHub Actions workflow file](https://github.com/pauldotyu/azure-voting-app/blob/main/.github/workflows/docker-image.yml), which builds and publishes the app to your new Azure Container Registry. You will need to [create repository secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository) so that your workflow can authenticate and publish to your registry.

Run the following commands to pull out the registry credentials:

> If you are using a new terminal, you will need to reset the `name` variable. Run the following command:
>
> name=<YOUR_DEPLOYMENT_NAME>

```bash
acrServer=$(az acr show --name "acr${name}" --query loginServer -o tsv)
acrUsername=$(az acr credential show --name "acr${name}" --query username -o tsv)
acrPassword=$(az acr credential show --name "acr${name}" --query "passwords[0].value" -o tsv)
```

Using the GitHub CLI, run the following commands to set your repository secrets

```bash
ghRepo="<YOUR_GITHUB_ACCOUNT>/<YOUR_REPO_NAME>"

gh auth login
gh secret set ACR_SERVER --body $acrServer --repo $ghRepo
gh secret set ACR_USERNAME --body $acrUsername --repo $ghRepo
gh secret set ACR_PASSWORD --body $acrPassword --repo $ghRepo
```

To push an image to the Azure Container Registry, create a new release using the following command:

```bash
gh release create v1.0.0 --notes "" --repo $ghRepo
```

Publishing a new release will trigger the GitHub Action workflow to build and publish the container image.

> The build and publish will take approximately 8-10 minutes

To view the output of the workflow, you can run these commands:

```bash
gh run view --repo $ghRepo
gh run view --repo $ghRepo --job=XXXXXXXXX        # your job number will be listed in the command above
gh run view --repo $ghRepo --log --job=XXXXXXXXXX # the log will be available when the job is complete
```

To validate your image, you can run the following:

```bash
az acr manifest list-metadata --registry "acr${name}" --name azure-vote-front
```

#### Deploy the Kubernetes manifest

The **azure-voting-app** repo includes a sample [Kubernetes manifest file](https://github.com/pauldotyu/azure-voting-app/blob/main/azure-voting-app-deploy.yaml) which you can use to deploy. There is a `<YOUR_ACR_SERVER>` placeholder in the file and this can be swapped out using the `sed` command.

The app deployment leverages [Kustomize](https://kustomize.io/) to customize your configuration at deployment time. The `kustomization.yaml` file includes a placeholder which you will swap out with your container registry server name. As the template is deployed to your Kubernetes cluster, Kustomize will replace the image value.

Run the following command to update your `kustomization.yaml` file.

```bash
sed -i'' -e "s/<YOUR_ACR_SERVER>/$acrServer/" kustomization.yaml
```

Now we can deploy the workload with the following command:

```bash
kubectl apply -k .
```

> 📝 NOTE
>
> Kustomize is built into `kubectl`

Inspect the pods to ensure they've deployed successfully:

```bash
kubectl get po

NAME                                READY   STATUS    RESTARTS   AGE
azure-vote-back-54576c54f-bktkk     1/1     Running   0          3m23s
azure-vote-front-5694d5cc45-fx87s   1/1     Running   0          3m23s
```

Inspect the service to ensure you can browse to the site:

```bash
kubectl get svc

NAME               TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
azure-vote-back    ClusterIP      10.0.136.122   <none>        6379/TCP       117s
azure-vote-front   LoadBalancer   10.0.74.8      20.81.58.34   80:30303/TCP   117s
kubernetes         ClusterIP      10.0.0.1       <none>        443/TCP        32m
```

Once the `EXTERNAL-IP` is populated for the `azure-vote-front` service, you can use the IP address and browse to the Azure Voting App 🚀

## Summary

Congratulations! 🎉

You've deployed an AKS cluster with an ARM64-based user node pool, built and published a new Azure Voting App container image which supports multiple OS architectures, and deployed the app into the AKS cluster. We also explored how we can inspect container image manifests to view the OS architectures they support. If your container images only support AMD64 OS architectures, you can easily re-target to support multiple platforms using Docker Buildx as demonstrated when we created a new release of the Azure Voting App. However, as we found in our exercise, you'll need to inspect the base layers of the container images to see if they also support ARM64.

## Cleanup

When you are finished exploring resources in this lab, you can delete the deployment by running the following commands:

```bash
az group delete --name "rg-${name}"
az deployment sub delete --name "${name}-deploy"
```

If you do not wish to keep the Azure Voting App repo in your GitHub account, you can delete it by running the following GitHub CLI commands:

```bash
gh auth refresh -h github.com -s delete_repo
gh repo delete $ghRepo
```
