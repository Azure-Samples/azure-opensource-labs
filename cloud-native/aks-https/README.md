# Tutorial: Deploy a Scalable & Secure Azure Kubernetes Service cluster using the Azure CLI Part 1
Azure Kubernetes Service provides a powerful way to manage Kubernetes applications which are Portable, extensibile, and when combined with Azure infrastructure highly scalable. Part 1 of this tutorial covers steps in creating a basic web voting application. Parts 2 and 3 will show how to scale the application and add a custom domain which is secured via https.

## Prerequisites
 - Access to Azure CLI with an active subscription. To install Azure CLI see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli.
 - If you have multiple Azure subscriptions, select the appropriate subscription ID in which the resources should be billed using the az account command.
 - This tutorial requires version 2.0.64 or later of the Azure CLI. If using Azure Cloud Shell, the latest version is already installed.
 - If you're using a local installation, sign in to the Azure CLI by using the az login command. To finish the authentication process, follow the steps displayed in your terminal. For other sign-in options, see Sign in with the Azure CLI..
 - Helm installed and configured. To install Helm see  https://helm.sh/docs/intro/install/.
- Consider using the Bash enviornment in Azure Cloud Shell. If using cloud shell Envsubst will need to be installed by running pip install envsubst


## Setup

### Define Default Command Line Variables 
This tutorial will use command line variables. Copy and run the following  the following to set default command line variables 

```bash
export RESOURCE_GROUP_NAME="myResourceGroup"
export RESOURCE_LOCATION="eastus"
export AKS_CLUSTER_NAME "myAKSCluster"
```

## Create A Resource Group
An Azure resource group is a logical group in which Azure resources are deployed and managed. When you create a resource group, you are prompted to specify a location. This location is:
  - The storage location of your resource group metadata.
  - Where your resources will run in Azure if you don't specify another region during resource creation.

Validate Resource Group does not already exist. If it does, select a new resource group name by running the following:

```bash
if [ "$(az group exists --name $RESOURCE_GROUP_NAME)" = 'true' ]; then export RAND=$RANDOM; export RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME$RAND"; echo "Your new Resource Group Name is $RESOURCE_GROUP_NAME"; fi
```

Create a resource group using the az group create command:
```
az group create --name $RESOURCE_GROUP_NAME --location $RESOURCE_LOCATION
```
The following is output for successful resource group creation

Results:

```expected_similarity=0.5
{
  "id": "/subscriptions/bb318642-28fd-482d-8d07-79182df07999/resourceGroups/testResourceGroup24763",
  "location": "eastus",
  "managedBy": null,
  "name": "testResourceGroup",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
```

## Create AKS Cluster 
Create an AKS cluster using the az aks create command with the --enable-addons monitoring parameter to enable Container insights. The following example creates a cluster named myAKSCluster with one node:

```bash
az aks create --resource-group $RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --node-count 1 --enable-addons monitoring --generate-ssh-keys
```

## Connect to the cluster
To manage a Kubernetes cluster, use the Kubernetes command-line client, kubectl. kubectl is already installed if you use Azure Cloud Shell.

1. Install az aks CLI locally using the az aks install-cli command

```bash
if ! [ -x "$(command -v kubectl)" ]; then az aks install-cli; fi
```

2. Configure kubectl to connect to your Kubernetes cluster using the az aks get-credentials command. The following command:
    - Downloads credentials and configures the Kubernetes CLI to use them.
    - Uses ~/.kube/config, the default location for the Kubernetes configuration file. Specify a different location for your Kubernetes configuration file using --file argument. 

> [!WARNING]
> This will overwrite any existing credentials with the same entry

```bash
az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --overwrite-existing
```

3. Verify the connection to your cluster using the kubectl get command. This command returns a list of the cluster nodes.

```bash
kubectl get nodes
```

The following output example shows the single node created in the previous steps. Make sure the node status is Ready:


## Deploy the Application 

A [Kubernetes manifest file](https://docs.microsoft.com/en-us/azure/aks/concepts-clusters-workloads#deployments-and-yaml-manifests) defines a cluster's desired state, such as which container images to run.

In this quickstart, you will use a manifest to create all objects needed to run the [Azure Vote application](https://github.com/Azure-Samples/azure-voting-app-redis). This manifest includes two Kubernetes deployments:

- The sample Azure Vote Python applications.
- A Redis instance.

Two [Kubernetes Services](https://docs.microsoft.com/en-us/azure/aks/concepts-network#services) are also created:

- An internal service for the Redis instance.
- An external service to access the Azure Vote application from the internet.

1. Create a file named azure-vote.yaml and copy in the following manifest.

    - If you use the Azure Cloud Shell, this file can be created using code, vi, or nano as if working on a virtual or physical system.

2. Deploy the application using the [kubectl apply](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#apply) command and specify the name of your YAML manifest:
```
kubectl apply -f azure-vote-start.yml
```

## Test the Application
When the application runs, a Kubernetes service exposes the application front end to the internet. This process can take a few minutes to complete.

Check progress using the kubectl get service command.

```bash
kubectl get service
```

Store the public IP Address as an environment variable for later use.
>[!Note]
> This commmand loops for 2 minutes and queries the output of kubectl get service for the IP Address. Sometimes it can take a few seconds to propogate correctly 
```bash
runtime="2 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do export IP_ADDRESS=$(kubectl get service azure-vote-front --output jsonpath='{.status.loadBalancer.ingress[0].ip}'); if ! [ -z $IP_ADDRESS ]; then break; else sleep 10; fi; done
```

Run the following command to obtain the IP Address
```bash
echo $IP_ADDRESS
```

To see the Azure Vote app in action, open a web browser to the external IP address of the application.


## Next steps

Learn how to scale an AKS Application with part 2 of the tutorial, see [Tutorial: Deploy a Scalable & Secure Azure Kubernetes Service cluster using the Azure CLI Part 2](./Part2ScaleYourApplication).