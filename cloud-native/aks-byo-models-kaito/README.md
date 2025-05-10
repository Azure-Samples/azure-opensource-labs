# BYO model on AKS with KAITO and open-source tools

This guide will walk you through the process of running any open-source model on Azure Kubernetes Service (AKS) with KAITO.

By the end of this walkthrough, you will be able to:

1. Deploy AKS cluster with KAITO installed and Azure Container Registry (ACR) using Terraform CLI
1. Import and unpack a ModelKit from HuggingFace using the Kit CLI
1. Create a Cog project and build an endpoint to test model predictions
1. Build Cog app container using Cog CLI and push container image to ACR
1. Pack ModelKit (model and code) to ACR
1. Build init container to download model at Pod startup
1. Deploy Cog container to AKS via KAITO workspace

### Why?

todo

### Pre-requisites

Before you begin, you will need the following tools installed.

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) for managing Azure resources.
- [Terraform](https://developer.hashicorp.com/terraform/install) for provisioning Azure resources.
- [Docker](https://www.docker.com/get-started/) for building and running container images.
- [KitOps CLI](https://kitops.org/docs/cli/installation/) for managing ModelKits.
- [Cog CLI](https://cog.run/getting-started/#install-cog) for building and running containerized inference applications.
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) for managing Kubernetes resources.
- [jq](https://jqlang.org/) for parsing JSON.
- [curl](https://curl.se/) for making HTTP requests.

> [!tip]
> This workshop can be run on any local machine with the above tools installed. However, if you are facing challenges with local compute power or network bandwidth, you can run this workshop on a cloud-based virtual machine. Check out this [README](./workstation/README.md) to run a Terraform template to deploy the a VM in Azure with all the tools pre-installed.

With the VM in place, SSH into the node and proceed with the rest of this walk-through.

## Getting started

To run this solution on AKS, use the Terraform script found in the KAITO repository which will provision the following services.

- Azure Kubernetes Service (AKS)
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli) (ACR)
- [Azure User-Assigned Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp)

### Provision AKS and install KAITO

Head over to the [KAITO repo](https://github.com/kaito-project/kaito), clone the project, and run the [Terraform script](https://github.com/kaito-project/kaito/tree/main/terraform).

```sh
git clone https://github.com/kaito-project/kaito.git
cd kaito/terraform
terraform init
```

In order to deploy to Azure you must be logged in to the Azure CLI.

```sh
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

Review the location variable in the `variables.tf` file and update accordingly, then run Terraform to provision resources.

```sh
terraform apply
```

This deployment will provision the cluster and install the KAITO Workspace and GPU Provisioner operators into the cluster via Helm.

Run the following command to export the outputs.

```sh
RG_NAME=$(terraform output -raw rg_name)
AKS_NAME=$(terraform output -raw aks_name)
```

Log in to AKS cluster:

```sh
az aks get-credentials -g $RG_NAME -n $AKS_NAME
```

Log in to ACR:

```sh
# get the acr name
ACR_NAME=$(az acr list -g $RG_NAME --query "[0].name" -o tsv)

# get the acr login server url
ACR_LOGIN_SERVER=$(az acr show -g $RG_NAME -n $ACR_NAME --query loginServer -o tsv)

# login to acr
az acr login -n $ACR_NAME
```

## Organize with KitOps

KitOps is an open-source project within the CNCF Sandbox that aims to standardize how AI projects are organized, versioned, and stored within OCI-compliant registries. We'll use the Kit CLI developed by friends at [jozu.ml](http://jozu.ml) to bootstrap our ModelKit project.

Navigate back to your home directory.

```sh
cd ~/
```

Create a new working directory.

```sh
mkdir mysmollm2app
cd mysmollm2app
```

Initialize a ModelKit by [importing a model](https://kitops.org/docs/cli/cli-reference/#kit-import) from HuggingFace. In this example, we’ll use the 16k context version of the [SmolLM2-1.7B-Instruct](https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-16k) LLM. Update the manifest when asked to set the name, author, description.

```sh
kit import https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-16k
```

[Unpack](https://kitops.org/docs/cli/cli-reference/#kit-unpack) the ModelKit to the current directory.

```sh
kit unpack huggingfacetb/smollm2-1.7b-instruct-16k:latest
```

## Predict with Cog

Cog is another open-source project developed by friends at Replicate which aims to standardize how AI/ML projects are packaged into production-ready containers. It provides a CLI that allows you to initialize Cog projects, which provides base images for Docker containers and includes boilerplate code to write inferencing calls against local models.

### Cog setup

Let's code the AI model prediction code using Cog and place the code within our KitOps ModelKit project. Run the following code to create a directory for the source code and initialize a new Cog project.

```sh
mkdir -p src/cog
cd src/cog
cog init
```

Reference: [https://cog.run/getting-started-own-model/#initialization](https://cog.run/getting-started-own-model/#initialization)

Open the requirements.txt file and replace the contents with the following packages.

```txt
torch==2.6.0
transformers==4.49.0
accelerate==1.5.2
```

Reference: [https://cog.run/yaml/#python_requirements](https://cog.run/yaml/#python_requirements)

Open the cog.yaml file and replace the YAML with the following config to define the Docker environment.

```yaml
build:
  gpu: true
  cuda: "12.6"
  python_version: 3.12
  python_requirements: requirements.txt
predict: "predict.py:Predictor"
image: "mysmollm2app"
```

Reference: [https://cog.run/yaml/#build](https://cog.run/yaml/#build) and [https://cog.run/getting-started-own-model/#define-the-docker-environment](https://cog.run/getting-started-own-model/#define-the-docker-environment) and [https://cog.run/yaml/#gpu](https://cog.run/yaml/#gpu)

### Cog predictions

Open the predict.py file and replace the code with the following.

```python
from cog import BasePredictor, Input
from transformers import AutoModelForCausalLM, AutoTokenizer
import os

class Predictor(BasePredictor):
    def setup(self) -> None:
        """Load the model into memory to make running multiple predictions efficient"""
        model_path = os.getenv("MODEL_PATH", "../../") # locally the model is in the root directory
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModelForCausalLM.from_pretrained(
            model_path,
            device_map="auto",  # Automatically distributes across available GPUs or uses CPU
            trust_remote_code=True
        )

    def predict(
        self,
        prompt: str = Input(description="Ask the LLM a question"),
    ) -> str:
        """Run a single prediction on the model"""
        inputs = self.tokenizer(prompt, return_tensors="pt", padding=True).to(self.model.device)

        outputs = self.model.generate(
            input_ids=inputs.input_ids,
            max_length=100,
            do_sample=True,
            top_p=0.95,
            temperature=0.3,
            attention_mask=inputs.attention_mask
        )

        response = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        return response
```

Reference: [https://cog.run/python/](https://cog.run/python/) and [https://cog.run/getting-started-own-model/#define-how-to-run-predictions](https://cog.run/getting-started-own-model/#define-how-to-run-predictions)

### Cog containers

Build the container image using the Cog CLI.

```sh
cog build
```

Reference: [https://cog.run/getting-started/#build-an-image](https://cog.run/getting-started/#build-an-image)

At this point, we could test this locally using cog predict or docker run commands, but we'll sidestep that and go straight to AKS.

Return to the root directory.

```sh
cd ../../
```

## Deploy the app to AKS

Let's run and test the application on the Azure infrastructure we provisioned using Terraform. Make sure you have environment variables set for the Azure resources before proceeding.

### Push Cog container to ACR

The cog build command created a container image. So we can simply run docker commands to tag and push the prediction code.

```sh
docker tag mysmollm2app:latest $ACR_LOGIN_SERVER/mysmollm2app:0.1.0
docker push $ACR_LOGIN_SERVER/mysmollm2app:0.1.0
```

Reference: [https://cog.run/getting-started/#build-an-image](https://cog.run/getting-started/#build-an-image)

### Push ModelKit to ACR

When we imported and unpacked the model using the Kit CLI, a ModelKit was created. The Cog container will not have the model included in the image build so we need to pack up the ModelKit and push it to an OCI-compliant registry.

But first, with a new src/cog folder in place for our Cog code, we need to update the ModelKit project to make it aware of the source code.

Open the Kitfile and add a new code spec at the end. Make sure the YAML looks like this.

```yaml
manifestVersion: 1.0.0
package:
  name: mysmollm2app
  authors:
    - Paul Yu
  description: My project working with HuggingFaceTB/SmolLM2-1.7B-Instruct-16k model
model:
  name: model
  path: model.safetensors
  parts:
    - path: training_args.bin
    - path: all_results.json
    - path: config.json
    - path: generation_config.json
    - path: merges.txt
    - path: special_tokens_map.json
    - path: tokenizer.json
    - path: tokenizer_config.json
    - path: train_results.json
    - path: trainer_state.json
    - path: vocab.json
docs:
  - path: README.md
    description: Readme file
code:
  - path: src/cog/
    description: Source code to run AI model predictions

```

Reference: [https://kitops.org/docs/kitfile/format/#example](https://kitops.org/docs/kitfile/format/#example)

Run the following command to pack up the ModelKit. This will pack up everything defined in the Kitfile.

```sh
kit pack . -t $ACR_LOGIN_SERVER/modelkits/mysmollm2:0.1.0
```

Reference: [https://kitops.org/docs/cli/cli-reference/#kit-pack](https://kitops.org/docs/cli/cli-reference/#kit-pack)

Run the following commands to create an ACR token to use for Kit CLI authentication and push the ModelKit to ACR.

```sh
# create token for push
ACR_TOKEN_NAME=kitpush
ACR_TOKEN_PASSWORD=$(az acr token create \
-n $ACR_TOKEN_NAME \
-r $ACR_NAME \
--scope-map _repositories_push \
--query "credentials.passwords[0].value" \
-otsv)

# login to acr
echo $ACR_TOKEN_PASSWORD | kit login $ACR_LOGIN_SERVER -u $ACR_TOKEN_NAME --password-stdin
kit push $ACR_LOGIN_SERVER/modelkits/mysmollm2:0.1.0
```

Reference: [https://kitops.org/docs/cli/cli-reference/#kit-push](https://kitops.org/docs/cli/cli-reference/#kit-push)

### Build a KitOps container for pulling ModelKits

When you deploy a Cog application, the model will need to be locally available. The model is stored within the ModelKit so we'll need a way to pull it out and save it to a place where the app can access it. In Kubernetes, we can implement this functionality via an initContainer which is the first thing that will run at deployment time to unpack our model in the Pod.

Create a custom container image to pull and unpack ModelKits from private registries. We'll be taking inspiration from [this example](https://github.com/kitops-ml/kitops/tree/main/build/dockerfiles/init).

```sh
mkdir src/kitops
cd src/kitops
```

Create a Dockerfile file and add the following code.

```Dockerfile
FROM alpine:latest
RUN wget https://github.com/jozu-ai/kitops/releases/latest/download/kitops-linux-x86_64.tar.gz && \
  tar -xzvf kitops-linux-x86_64.tar.gz && \
  mv kit /usr/local/bin/

# Set default values for environment variables
ENV UNPACK_PATH=/home/user/modelkit/
ENV UNPACK_FILTER=model

CMD echo $PASSWORD | kit login $REGISTRY_URL -u $USERNAME --password-stdin && \
  kit unpack "$MODELKIT_REF" --dir "$UNPACK_PATH" --filter="$UNPACK_FILTER"
```

Reference: [https://github.com/kitops-ml/kitops/blob/main/build/dockerfiles/init/Dockerfile](https://github.com/kitops-ml/kitops/blob/main/build/dockerfiles/init/Dockerfile)

Build and push the init container.

```sh
docker build -t $ACR_LOGIN_SERVER/kitunpacker:0.1.0 .
docker push $ACR_LOGIN_SERVER/kitunpacker:0.1.0
```

### Deploy custom model workspace

With KAITO workspace CRD deployed in the cluster, we just need to create a custom resource called a Workspace and KAITO will take care of provisioning a GPU-based node, deploying the application in a Pod and exposing it with a Service.

The Pod deployment in the workspace will leverage the KitOps init container to pull and unpack the model from the ModelKit; however, it will need to authenticate against the ACR.

Run the following commands to create a separate ACR token to pull ModelKits from ACR.

```sh
# create token for pull
ACR_TOKEN_NAME=kitpull
ACR_TOKEN_PASSWORD=$(az acr token create \
-n $ACR_TOKEN_NAME \
-r $ACR_NAME \
--scope-map _repositories_pull \
--query "credentials.passwords[0].value" \
-otsv)

# create kubernetes secret which will be used in the initContainer config
kubectl create secret generic kitops-init-token \
--from-literal=REGISTRY_URL=$ACR_LOGIN_SERVER \
--from-literal=USERNAME=$ACR_TOKEN_NAME \
--from-literal=PASSWORD=$ACR_TOKEN_PASSWORD
```

Run the following command to create a Workspace.

```yaml
kubectl apply -f - <<EOF
apiVersion: kaito.sh/v1alpha1
kind: Workspace
metadata:
  name: mysmollm2app-workspace
resource:
  instanceType: Standard_NC6s_v3
  labelSelector:
    matchLabels:
      apps: mysmollm2app
inference:
  template:
    spec:
      initContainers:
        - name: kitops-init
          image: $ACR_LOGIN_SERVER/kitunpacker:0.1.0
          envFrom:
            - secretRef:
                name: kitops-init-token
          env:
            - name: MODELKIT_REF
              value: "$ACR_LOGIN_SERVER/modelkits/mysmollm2:0.1.0"
            - name: UNPACK_PATH
              value: /tmp/mymodelkit
            - name: UNPACK_FILTER
              value: model
          volumeMounts:
            - name: modelkit-storage
              mountPath: /tmp/mymodelkit    
      containers:
        - name: mysmollm2app
          image: $ACR_LOGIN_SERVER/mysmollm2app:0.1.0
          env:
            - name: MODEL_PATH
              value: "/mymodel"
          resources: {}
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: modelkit-storage
              mountPath: /mymodel
            - name: dshm
              mountPath: /dev/shm
      volumes:
        - name: modelkit-storage
          emptyDir: {}
        - name: dshm
          emptyDir:
            medium: Memory
EOF
```

Once KAITO processes this custom resource, it will begin provisioning a new GPU node, attaching it to the cluster and deploying a new Pod. As the new Pod is being rolled out, the initContainer will be responsible for downloading the model to a local directory and making it available for the Cog inference server.

Reference: [https://kitops.org/docs/deploy/](https://kitops.org/docs/deploy/) and [https://github.com/kaito-project/kaito/blob/main/docs/custom-model-integration/custom-deployment-template.yaml](https://github.com/kaito-project/kaito/blob/main/docs/custom-model-integration/custom-deployment-template.yaml)

Watch the Workspace roll out and wait for the RESOURCEREADY status to show True.

```sh
$ kubectl get workspace -w
NAME                     INSTANCE           RESOURCEREADY   INFERENCEREADY   JOBSTARTED   WORKSPACESUCCEEDED   AGE
mysmollm2app-workspace   Standard_NC6s_v3   True            True                          True                 8m6s
```

Once the Workspace resource is ready, the Pod will begin to roll out.

Watch the Pod rollout and wait for the status to show Running.

```sh
$ kubectl get pod
NAME                                      READY   STATUS    RESTARTS   AGE
mysmollm2app-workspace-5c4695c9f7-44mkp   1/1     Running   0          17m
```

When the Pod is running you can also confirm the Service is deployed as well.

```sh
$ kubectl get svc
NAME                     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)            AGE
kubernetes               ClusterIP   10.0.0.1      <none>        443/TCP            1h
mysmollm2app-workspace   ClusterIP   10.0.159.30   <none>        80/TCP,29500/TCP   19m
```

### Run a prediction

Run the following command to port-forward the Service so you can test the prediction endpoint locally.

```sh
kubectl port-forward svc/mysmollm2app-workspace 8393:80
```

In the terminal, press ctrl+z to suspend the process then type bg to resume the process and move it to the background.

Run the following curl command to verify the inference server is ready.

```sh
curl -s http://localhost:8393/health-check | jq
```

You should see output similar to the following.

```json
{
  "status": "READY",
  "setup": {
    "started_at": "2025-04-28T23:05:09.813581+00:00",
    "completed_at": "2025-04-28T23:05:15.948367+00:00",
    "logs": "",
    "status": "succeeded"
  }
}
```

Once you see the status is READY, you can call the prediction endpoint and ask the open-source model a question.

```sh
curl -s http://localhost:8393/predictions -X POST \
 -H 'Content-Type: application/json' \
 -d '{"input": {"prompt": "what is kubernetes?"}}' | jq
```

You should see output similar to the following.

```json
{
  "input": {
    "prompt": "what is kubernetes?"
  },
  "output": "what is kubernetes?\nKubernetes is an open-source container orchestration system that automates the deployment, scaling, and management of containerized applications. It provides a platform for deploying, managing, and monitoring containerized applications, making it easier to build, ship, and run applications at scale.\n\nKubernetes was originally developed by Google and is now maintained by the Cloud Native Computing Foundation (CNCF). It is widely used in production environments, including cloud providers, data",
  "id": null,
  "version": null,
  "created_at": null,
  "started_at": "2025-04-29T00:16:08.232950+00:00",
  "completed_at": "2025-04-29T00:16:10.899297+00:00",
  "logs": "",
  "error": null,
  "status": "succeeded",
  "metrics": {
    "predict_time": 2.666347
  }
}
```

Press fg to move the port-forward process back to the foreground then press ctrl+c to stop the port-forward.

## Summary

Congratulations! You just used the Kit and Cog open-source tools to deploy an open-source model to Azure Kubernetes Service using KAITO.

Maybe add some suggestions for next steps here…

## Cleanup

When you are done testing, either go back to the directory where you ran the Terraform from, or run the following command.

```sh
az group delete -n $RG_NAME -y --no-wait
```
