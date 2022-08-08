# Tutorial: Deploy a Scalable & Secure Azure Kubernetes Service cluster using the Azure CLI Part 3
Azure Kubernetes Service provides a powerful way to manage Kubernetes applications which are Portable, extensibile, and when combined with Azure infrastructure highly scalable. Part 3 of this tutorial covers steps in adding a custom domain with https to an AKS Application.

## Prerequisites
In the previous tutorials a sample application was created and an Application Gateway Ingress controller was added. If you haven't done these steps, and would like to follow along, complete [Parts 1 & 2](../Part2ScaleYourApplication/README.md)
## Setup

### Define Custom Command Line Variables 
Custom values are required for the following inputs.

We will now choose and define the custom domain which your application will use. The application will be reachable at {mycustomdomain}.eastus.cloudapp.azure.com
 
 Run the following command with a unique custom domain:
>[!Note] Do not add any capitalization or .com. The custom domain must be unique and fit the pattern: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$

```
export CUSTOM_DOMAIN_NAME="myuniquecustomdomain"
```

You can validate the custom domain works by running the following 
```
if [[ ! $CUSTOM_DOMAIN_NAME =~ ^[a-z][a-z0-9-]{1,61}[a-z0-9] ]]; then echo "Invalid Domain, run'export CUSTOM_DOMAIN_NAME="customdomainname"' again and choose a new domain"; else echo "Custom Domain Set!"; fi; 
```

In order to obtain an SSL certificate from Lets Encrpyt we need to provide a valid email address.

Set a valid email address for SSL validation by running the following:
```
export SSL_EMAIL_ADDRESS="myemailadress@gmail.com"
```

## Add custom domain to AGIC
Now that Application Gateway Ingress has been added, the next step is to add a custom domain. This will allow the endpoint to be reached by a human readable URL as well as allow for SSL Termination at the endpoint.

1. Store Unique ID of the Public IP Address as an environment variable by running the following:

```bash
export PUBLIC_IP_ID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP_ADDRESS')].[id]" --output tsv)
```

2. Update public IP to respond to custom domain requests by running the following:

```bash
az network public-ip update --ids $PUBLIC_IP_ID --dns-name $CUSTOM_DOMAIN_NAME
```

3. Run the following command to see the fully qualified domain name (FQDN) of your application. 

```bash
az network public-ip show --ids $PUBLIC_IP_ID --query "[dnsSettings.fqdn]" --output tsv
```

    Validate the domain works by opening a web browser to the FQDN of the application.

4. Store the custom domain as en enviornment variable. This will be used later when setting up https termination.

```bash
export FQDN=$(az network public-ip show --ids $PUBLIC_IP_ID --query "[dnsSettings.fqdn]" --output tsv)
```

## Add HTTPS termination to custom domain 
At this point in the tutorial you have an AKS web app with Application Gateway as the Ingress controller and a custom domain you can use to access your application. The next step is to add an SSL certificate to the domain so that users can reach your application securely via https.  

### Set Up Cert Manager
In order to add HTTPS we are going to use Cert Manager. Cert Manager is an open source tool used to obtain and manage SSL certificate for Kubernetes deployments. Cert Manager will obtain certificates from a variety of Issuers, both popular public Issuers as well as private Issuers, and ensure the certificates are valid and up-to-date, and will attempt to renew certificates at a configured time before expiry.

1. In order to install cert-manager, we must first create a namespace to run it in. This tutorial will install cert-manager into the cert-manager namespace. It is possible to run cert-manager in a different namespace, although you will need to make modifications to the deployment manifests.
```
kubectl create namespace cert-manager
```

2. We can now install cert-manager. All resources are included in a single YAML manifest file. This can be installed by running the following:
```
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.0/cert-manager.crds.yaml
```


3. Add the certmanager.k8s.io/disable-validation: "true" label to the cert-manager namespace by running the following. This will allow the system resources that cert-manager requires to bootstrap TLS to be created in its own namespace.
```
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

### Obtain certificate via Helm Charts
Helm is a Kubernetes deployment tool for automating creation, packaging, configuration, and deployment of applications and services to Kubernetes clusters.

Cert-manager provides Helm charts as a first-class method of installation on Kubernetes.

1. Add the Jetstack Helm repository
This repository is the only supported source of cert-manager charts. There are some other mirrors and copies across the internet, but those are entirely unofficial and could present a security risk.
```
helm repo add jetstack https://charts.jetstack.io
```

2. Update local Helm Chart repository cache 
```
helm repo update
```

3. Install Cert-Manager addon via helm by running the following:
```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.7.0
```

4. Deploy Cluster Issuer 

    ClusterIssuers are Kubernetes resources that represent certificate authorities (CAs) that are able to generate signed certificates by honoring certificate signing requests. All cert-manager certificates require a referenced issuer that is in a ready condition to attempt to honor the request.

    - Create a file named cluster-issuer-prod.yaml and copy in the following manifest.

    - If you use the Azure Cloud Shell, this file can be created using code, vi, or nano as if working on a virtual or physical system.

        
    - Deploy the Cluster Issuer YAML file by running the following command:
        >[!NOTE] envsubst will replace variables in the YAML file with command line variables previosuly defined
```
envsubst < cluster-issuer-prod.yaml | kubectl apply -f -
```

5. Create and deploy Updated YAML manifest which includes ssl termination
 - Create a file named azure-vote-agic-ssl.yml and copy in the following manifest.

- Deploy the YAML file complete with SSL termination by running the following command: 
    >[!NOTE] envsubst will replace variables in the YAML file with command line variables previosuly defined

```
envsubst < azure-vote-agic-ssl.yml | kubectl apply -f -
```
## Validate application is working

Wait for SSL certificate to issue. The following command will query the status of the SSL certificate for 3 minutes.
 In rare occasions it may take up to 15 minutes for Lets Encrypt to issue a successful challenge and the ready state to be 'True'
```
runtime="10 minute"; endtime=$(date -ud "$runtime" +%s); while [[ $(date -u +%s) -le $endtime ]]; do STATUS=$(kubectl get certificate --output jsonpath={..status.conditions[0].status}); echo $STATUS; if [ "$STATUS" = 'True' ]; then break; else sleep 10; fi; done
```

Validate SSL certificate is True by running the follow command:
```
kubectl get certificate --output jsonpath={..status.conditions[0].status}
```

The following is a successful output

Results:
```expected_similarity=0.8
True
```

## Browse your AKS Deployment Secured via HTTPS!
Run the following command to get the HTTPS endpoint for your application:

>[!Note]
> It often takes 2-3 minutes for the SSL certificate to propogate and the site to be reachable via https 
```
echo https://$FQDN
```
To see the Azure Vote app in action, open a web browser to the HTTPS Endpoint of the Application.