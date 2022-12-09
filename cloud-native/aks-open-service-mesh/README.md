# Azure Kubernetes Service with Open Service Mesh

In this multi-part lab, you will deploy an [AKS][aks] cluster with the [Web Application Routing (Preview)][aks_addon_web_app_routing] and [Open Service Mesh (OSM)][aks_addon_osm] add-ons enabled. These add-ons are open-source components that are installed and managed by the AKS platform. OSM can be installed on any Kubernetes cluster (see [guide](https://release-v1-2.docs.openservicemesh.io/docs/getting_started/install_apps/)); however, in this lab, you will explore the AKS-managed version and demonstrate how it integrates with other components.

We'll start by deploying the [OSM Bookstore sample application][osm_bookstore_sample] to the AKS cluster, expose the web applications via the managed ingress controller then configure OSM to secure traffic between the ingress controller and backend services (as well as inter-mesh communications).

## Requirements

Before you get started, make sure you have the following:

* An Azure Subscription (e.g. [Free](https://aka.ms/azure-free-account) or [Student](https://aka.ms/azure-student-account) account)
* The [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) with [Azure Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install#azure-cli) installed
* A [GitHub](https://github.com/) account
* The [`kubectl` CLI](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
* Bash shell (e.g. macOS, Linux, [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/windows/wsl/about), [Multipass](https://multipass.run/), [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/quickstart), [GitHub Codespaces](https://github.com/features/codespaces), etc)
* The [`osm` CLI](https://learn.microsoft.com/azure/aks/open-service-mesh-binary?pivots=client-operating-system-linux)

## Deploy Azure Resources

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fazure-opensource-labs%2Fmain%2Fcloud-native%2Faks-open-service-mesh%2Fmain.json)

> Use the button above if you'd like to deploy using the Azure Portal instead of Azure CLI commands.

Clone this repo and drop into the `aks-open-service-mesh` directory.

```bash
git clone https://github.com/Azure-Samples/azure-opensource-labs.git
cd azure-opensource-labs/cloud-native/aks-open-service-mesh
```

Open a terminal and initialize the following variables which will be passed into the deployment.

```bash
# azure region where resources will be deployed to
location=eastus

# random name that will be used for azure resources
name=books$RANDOM

# get the latest (n-1) version of kubernetes
kubernetesVersion=$(az aks get-versions -l $location -o table | head -4 | tail -n 1 | cut -f 1 -d ' ')

# kubernetes node count
systemNodeCount=3

# azure vm size for nodes
systemNodeSize=Standard_D4s_v5

# get your user name
userName=$(az account show --query user.name -o tsv)

# get your user principal id
userObjectId=$(az ad user show --id $userName --query id -o tsv)

# ensure you have the following providers
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Insights
```

Deploy Azure infrastructure with the Azure Bicep template.

> Take a look at this [blog post](https://dev.to/azure/sharing-bicep-modules-with-azure-container-registry-4mo0) to see how the Bicep modules are put together.

```bash
az deployment sub create \
  --name "$name-deploy" \
  --location $location \
  --template-file main.bicep \
  --parameters name=$name \
               location=$location \
               kubernetesVersion=$kubernetesVersion \
               systemNodeCount=$systemNodeCount \
               systemNodeSize=$systemNodeSize \
               userObjectId=$userObjectId
```

The template will deploy the following resources into your subscription:

* [Azure Resource Group][rg] to deploy resources into
* [Azure Log Analytics Workspace][law] to serve as a data store for the monitoring add-on
* [Azure Kubernetes Service][aks] your managed Kubernetes cluster with [`kubenet`][kubenet] as the container network plugin and [`calico`][calico] for network policy and include the following [AKS add-ons][aks_addons]
  * [`azure-keyvault-secrets-provider`](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver)
  * [`monitoring`](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview)
  * [`open-service-mesh`](https://learn.microsoft.com/azure/aks/open-service-mesh-about)
  * [`web_application_routing`](https://learn.microsoft.com/azure/aks/web-app-routing?tabs=with-osm)

## Validate the Azure deployment

View a list of resources deployed in your resource group by running the following command or view from the [Azure Portal](https://portal.azure.com):

```bash
az resource list --resource-group rg-$name -o table
```

To view the AKS add-ons that have been installed and its configurations, run the command below:

```bash
az aks show -g rg-${name} -n aks-${name} --query "addonProfiles"
```

## Validate access to the Kubernetes cluster

Before we pull down credentials from AKS make sure you have `kubectl` CLI locally.

> If you do not have `kubectl` installed yet, you can run the following command to install it using Azure CLI command: `az aks install-cli`

Run the following command to download credential for `kubectl` CLI:

```bash
az aks get-credentials -g rg-${name} -n aks-${name}
```

Run the following command to verify you have access to the cluster:

```bash
kubectl cluster-info
```

## Validate OSM resources and configurations

Now let's check the OSM add-on by running the following command and ensure `openServiceMesh` has the `enabled` property set to `true`.

```bash
az aks show -g rg-${name} -n aks-${name} --query "addonProfiles.openServiceMesh"
```

Next, run the following command to check the OSM resources have been deployed into your cluster successfully.

```bash
kubectl api-resources | grep openservicemesh
```

You should see output similar to the following:

```text
meshconfigs                        meshconfig               config.openservicemesh.io/v1alpha2     true         MeshConfig
meshrootcertificates               mrc                      config.openservicemesh.io/v1alpha2     true         MeshRootCertificate
egresses                           egress                   policy.openservicemesh.io/v1alpha1     true         Egress
ingressbackends                    ingressbackend           policy.openservicemesh.io/v1alpha1     true         IngressBackend
retries                            retry                    policy.openservicemesh.io/v1alpha1     true         Retry
upstreamtrafficsettings            upstreamtrafficsetting   policy.openservicemesh.io/v1alpha1     true         UpstreamTrafficSetting
```

OSM installs several new [Custom Resource Definitions (CRDs)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) as part of its implementation.

Let's view OSM deployments by querying for deployments that start with `osm`.

```bash
kubectl get deploy -A | grep osm
```

You should see output similar to this:

```text
kube-system          osm-bootstrap                       1/1     1            1           132m
kube-system          osm-controller                      2/2     2            2           132m
kube-system          osm-injector                        2/2     2            2           132m
```

Here is a high-level overview of the [OSM components][osm] that are installed:

* `osm-bootstrap` runs on a single node and is responsible for installing itself in the cluster and installing CRDs
* `osm-controller` runs on all nodes and is the control plane of the service mesh
* `osm-injecter` runs on all nodes and is responsible for injecting data plane components (i.e., Envoy proxy sidecars) into application pods

These resources are typically [installed manually using the OSM CLI command `osm install`](https://release-v1-2.docs.openservicemesh.io/docs/getting_started/setup_osm/#installing-osm-on-kubernetes). However, with the AKS add-on, the installation and configuration is done for you and when OSM is deployed with the Web Application Routing add-on, Azure automatically adds additional configuration to allow NGINX and OSM to work together.

> With open-source OSM, you have an option on the namespace where `osm` is installed (normally in the `osm-system` namespace), but since this is managed by AKS, it has been installed in the `kube-system` namespace for you.

To view the default configuration for OSM, you can run the following command.

```bash
kubectl get meshconfig osm-mesh-config -n kube-system -o yaml
```

Pay special attention to the `traffic` configuration; a snippet has been included below.

```text
...
traffic:
    enableEgress: true
    enablePermissiveTrafficPolicyMode: true
    inboundExternalAuthorization:
      enable: false
      failureModeAllow: false
      statPrefix: inboundExtAuthz
      timeout: 1s
...
```

The `enablePermissiveTrafficPolicyMode` has been set to `true`. This is the default configuration and when set to `true`, pods enrolled in the service mesh communicate freely. For more info on this see: [Permissive Traffic Policy Mode][osm_permissive_traffic_policy]

### Namespaces are vital to OSM

Applications are added to OSM based on namespaces. By binding to [Kubernetes namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/), the OSM controller labels and annotates these resources so that it can discover and manage data plane components of the mesh.

Run this command to view the services meshes deployed withing OSM.

```bash
osm mesh list
```

You should see output similar to the following:

```text
MESH NAME   MESH NAMESPACE   VERSION   ADDED NAMESPACES
osm         kube-system      v1.2.1    app-routing-system

MESH NAME   MESH NAMESPACE   SMI SUPPORTED
osm         kube-system      HTTPRouteGroup:v1alpha4,TCPRoute:v1alpha4,TrafficSplit:v1alpha2,TrafficTarget:v1alpha3

To list the OSM controller pods for a mesh, please run the following command passing in the mesh's namespace
        kubectl get pods -n <osm-mesh-namespace> -l app=osm-controller
```

> Note the Service Mesh Interface (SMI) specs that are supported by OSM. These may be subject to change with the ongoing dialog on [The GAMMA Initiative](https://gateway-api.sigs.k8s.io/contributing/gamma/) happening within the community.

As suggested in the output above, let's get a list of OSM controller pods.

```bash
kubectl get pods -n kube-system -l app=osm-controller
```

Run this command to view the namespaces OSM is currently monitoring:

```bash
osm namespace list
```

You should see output similar to the following:

```text
NAMESPACE            MESH   SIDECAR-INJECTION
app-routing-system   osm    disabled
```

As mentioned above, we've added both the `web_application_routing` and `open-service-mesh` add-ons and Azure has automatically configured OSM to monitor the NGINX ingress controller's namespace 🎉

One important thing to note in the output above is that `SIDECAR-INJECTION` has been set to `disabled`. OSM integration with NGINX requires monitoring of the ingress controller's namespace for service discovery and management of ingress endpoints to backend services. However, OSM should not inject sidecars into the NGINX pods to function properly.

Now, let's inspect the namespace labels added by OSM.

```bash
kubectl get namespace --show-labels | grep openservicemesh.io/monitored-by=osm
```

## Next steps

We've successfully deployed the AKS cluster and inspected how the Web Application Routing and OSM add-ons are deployed and configured in the cluster. The cluster is now ready for application deployments.

Head over to [Part 2: Bookstore application deployment](./02-deploying-bookstore-app/README.md) to deploy our first app.

## Resources

* [AKS Add-On: Web Application Routing (Preview)][aks_addon_web_app_routing]
* [AKS Add-On: Open Service Mesh][aks_addon_osm]

<!-- RESOURCE_URLS -->
[aks_addons]:https://learn.microsoft.com/azure/aks/integrations#available-add-ons
[aks_addon_osm]:https://learn.microsoft.com/azure/aks/open-service-mesh-about
[aks_addon_web_app_routing]:https://learn.microsoft.com/azure/aks/web-app-routing?tabs=with-osm
[osm]:https://release-v1-2.docs.openservicemesh.io/docs/overview/about/
[osm_bookstore_sample]:https://release-v1-2.docs.openservicemesh.io/docs/getting_started/install_apps/
[osm_permissive_traffic_policy]:https://release-v1-2.docs.openservicemesh.io/docs/guides/traffic_management/permissive_mode/
[kubenet]:https://learn.microsoft.com/azure/aks/configure-kubenet
[calico]:https://projectcalico.docs.tigera.io/security/kubernetes-policy
[rg]:https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-portal#what-is-a-resource-group
[law]:https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-workspace-overview
[aks]:https://learn.microsoft.com/azure/aks/intro-kubernetes
