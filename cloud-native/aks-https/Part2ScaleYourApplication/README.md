# Tutorial: Deploy a Scalable & Secure Azure Kubernetes Service cluster using the Azure CLI Part 2
Azure Kubernetes Service provides a powerful way to manage Kubernetes applications which are Portable, extensibile, and when combined with Azure infrastructure highly scalable. Part 2 of this tutorial covers steps in scaling an AKS application by adding Application Gateway Ingress.

## Prerequisites
In the previous tutorials a sample application was created and an Application Gateway Ingress controller was added. If you haven't done these steps, and would like to follow along, complete [Part 1 - Deploy a Voting App](../Part1VotingApp/README.md)


## Setup

### Define Default Command Line Variables 
This tutorial will use command line variables. Copy and run the following  the following to set default command line variables 

```bash
export PUBLIC_IP_NAME="myPublicIp"
export VNET_NAME="myVnet"
export SUBNET_NAME="mySubnet"
export APPLICATION_GATEWAY_NAME="myApplicationGateway"
export APPGW_TO_AKS_PEERING_NAME="AppGWtoAKSVnetPeering"
export AKS_TO_APPGW_PEERING_NAME="AKStoAppGWVnetPeering"
```

## Add Application Gateway Ingress Controller
The Application Gateway Ingress Controller (AGIC) is a Kubernetes application, which makes it possible for Azure Kubernetes Service (AKS) customers to leverage Azure's native Application Gateway L7 load-balancer to expose cloud software to the Internet. AGIC monitors the Kubernetes cluster it is hosted on and continuously updates an Application Gateway, so that selected services are exposed to the Internet

AGIC helps eliminate the need to have another load balancer/public IP in front of the AKS cluster and avoids multiple hops in your datapath before requests reach the AKS cluster. Application Gateway talks to pods using their private IP directly and does not require NodePort or KubeProxy services. This also brings better performance to your deployments.

## Deploy a new Application Gateway 
1. Create a Public IP for Application Gateway by running the following:
```
az network public-ip create --name $PUBLIC_IP_NAME --resource-group $RESOURCE_GROUP_NAME --allocation-method Static --sku Standard
```

2. Create a Virtual Network(Vnet) for Application Gateway by running the following:
```
az network vnet create --name $VNET_NAME --resource-group $RESOURCE_GROUP_NAME --address-prefix 11.0.0.0/8 --subnet-name $SUBNET_NAME --subnet-prefix 11.1.0.0/16 
```

3. Create Application Gateway by running the following:

> [!NOTE] 
> This will take around 5 minutes 
```
az network application-gateway create --name $APPLICATION_GATEWAY_NAME --location $RESOURCE_LOCATION --resource-group $RESOURCE_GROUP_NAME --sku Standard_v2 --public-ip-address $PUBLIC_IP_NAME --vnet-name $VNET_NAME --subnet $SUBNET_NAME
```

## Enable the AGIC add-on in existing AKS cluster 

1. Store Application Gateway ID by running the following:
```
APPLICATION_GATEWAY_ID=$(az network application-gateway show --name $APPLICATION_GATEWAY_NAME --resource-group $RESOURCE_GROUP_NAME --output tsv --query "id") 
```

2. Enable Application Gateway Ingress Addon by running the following:

> [!NOTE]
> This will take a few minutes
```
az aks enable-addons --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --addon ingress-appgw --appgw-id $APPLICATION_GATEWAY_ID
```

3. Store the node resource as an environment variable group by running the following:
```
NODE_RESOURCE_GROUP=$(az aks show --name myAKSCluster --resource-group $RESOURCE_GROUP_NAME --output tsv --query "nodeResourceGroup")
```
4. Store the Vnet name as an environment variable by running the following:
```
AKS_VNET_NAME=$(az network vnet list --resource-group $NODE_RESOURCE_GROUP --output tsv --query "[0].name")
```

5. Store the Vnet ID as an environment variable by running the following:
```
AKS_VNET_ID=$(az network vnet show --name $AKS_VNET_NAME --resource-group $NODE_RESOURCE_GROUP --output tsv --query "id")
```
## Peer the two virtual networks together 
Since we deployed the AKS cluster in its own virtual network and the Application Gateway in another virtual network, you'll need to peer the two virtual networks together in order for traffic to flow from the Application Gateway to the pods in the cluster. Peering the two virtual networks requires running the Azure CLI command two separate times, to ensure that the connection is bi-directional. The first command will create a peering connection from the Application Gateway virtual network to the AKS virtual network; the second command will create a peering connection in the other direction.

1. Create the peering from Application Gateway to AKS by runnig the following:
```
az network vnet peering create --name $APPGW_TO_AKS_PEERING_NAME --resource-group $RESOURCE_GROUP_NAME --vnet-name $VNET_NAME --remote-vnet $AKS_VNET_ID --allow-vnet-access 
```

2. Store Id of Application Gateway Vnet As enviornment variable by running the following:
```
APPLICATION_GATEWAY_VNET_ID=$(az network vnet show --name $VNET_NAME --resource-group $RESOURCE_GROUP_NAME --output tsv --query "id")
```
3. Create Vnet Peering from AKS to Application Gateway
```
az network vnet peering create --name $AKS_TO_APPGW_PEERING_NAME --resource-group $NODE_RESOURCE_GROUP --vnet-name $AKS_VNET_NAME --remote-vnet $APPLICATION_GATEWAY_VNET_ID --allow-vnet-access
```
4. Store New IP address as environment variable by running the following command:
```
runtime="2 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do export IP_ADDRESS=$(az network public-ip show --resource-group $RESOURCE_GROUP_NAME --name $PUBLIC_IP_NAME --query ipAddress --output tsv); if ! [ -z $IP_ADDRESS ]; then break; else sleep 10; fi; done
```

## Apply updated application YAML complete with AGIC

1. Create a file named azure-vote-agic-yaml and copy in the following manifest.

    - If you use the Azure Cloud Shell, this file can be created using code, vi, or nano as if working on a virtual or physical system.


2. Deploy the updated Voting App AGIC YAML file with Application Gateway Ingress added by running the following command:

```
kubectl apply -f azure-vote-agic.yml
```

## Check that the application is reachable
Now that the Application Gateway is set up to serve traffic to the AKS cluster, let's verify that your application is reachable. 

Check that the sample application you created is up and running by either visiting the IP address of the Application Gateway that get from running the following command or check with curl. It may take Application Gateway a minute to get the update, so if the Application Gateway is still in an "Updating" state on Portal, then let it finish before trying to reach the IP address. Run the following to check the status:
```
kubectl get ingress
```

Run the following command to obtain the IP Address of Application Gateway
```
echo $IP_ADDRESS
```

To see the Azure Vote app in action, open a web browser to the external IP address of the application.

## Next steps

Learn how to scale an AKS Application with part 2 of the tutorial, see [Tutorial: Deploy a Scalable & Secure Azure Kubernetes Service cluster using the Azure CLI Part 3](../Part3CustomDomainAndHttps).