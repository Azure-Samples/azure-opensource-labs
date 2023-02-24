# Kubeflow on Azure Kubernetes Service (AKS) (Basic)

This is the Basic scenario for deployment of Kubeflow via the Azure CLI without any additional configuration. See [README.md](README.md) for the Advanced scenario.

## Deploy AKS

In this lab we will be using Azure Kubernetes Service (AKS) cluster which we will [deploy using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough#connect-to-the-cluster). Make sure you have the [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) before you continue.

Set some environment variables

```
RESOURCE_GROUP='my-aks'
KUBERNETES_VERSION='1.24.9'
NODE_VM_SIZE='Standard_D2s_v5'
```

Note that the latest 1.24.* `KUBERNETES_VERSION` was discovered via the following command:

```
az aks get-versions \
  --location eastus \
  --query 'orchestrators[].orchestratorVersion' \
  --out table
```

Create a Resource Group

```
az group create --name $RESOURCE_GROUP \
    --location eastus
```

Create an AKS cluster

```
az aks create --resource-group $RESOURCE_GROUP \
  --name aks1 \
  --node-count 3 \
  --node-vm-size $NODE_VM_SIZE \
  --kubernetes-version $KUBERNETES_VERSION \
  --enable-addons monitoring \
  --generate-ssh-keys
```

Install `kubectl` if you do not have it installed already

```
az aks install-cli
```

Configure `kubectl` to authenticate to your cluster

```
az aks get-credentials --resource-group $RESOURCE_GROUP \
  --name aks1
```

## Install kustomize

Next we will install the [kustomize](https://kustomize.io/) binary from its [GitHub release](https://github.com/kubernetes-sigs/kustomize/releases/tag/v3.2.0). If you are on macOS, update `PLATFORM` from `linux` to `darwin`.

```
PLATFORM='darwin'

curl -OL "https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_${PLATFORM}_amd64"

chmod +x "kustomize_3.2.0_${PLATFORM}_amd64"

sudo mv "kustomize_3.2.0_${PLATFORM}_amd64" /usr/local/bin/kustomize
```

## Deploy Kubeflow

First download the manifests from [kubeflow/manifests](https://github.com/kubeflow/manifests)

```
git clone https://github.com/kubeflow/manifests.git -b v1.6.1

cd manifests/
```

Install all of the components via a single command

```
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
```

Once the command has completed, check the pods are ready

```
kubectl get pods -n cert-manager
kubectl get pods -n istio-system
kubectl get pods -n auth
kubectl get pods -n knative-eventing
kubectl get pods -n knative-serving
kubectl get pods -n kubeflow
kubectl get pods -n kubeflow-user-example-com
```

Run `kubctl port-forward` to access the Kubeflow dashboard

```
kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80
```

Finally, open [http://localhost:8080](http://localhost:8080/) and login with the default user's credentials. The default email address is `user@example.com` and the default password is `12341234`.
