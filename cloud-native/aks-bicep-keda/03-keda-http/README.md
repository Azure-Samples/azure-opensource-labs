# KEDA HTTP Add-on

Install KEDA (via [YAML files](https://keda.sh/docs/2.7/deploy/#yaml)). You can also use [Helm](https://keda.sh/docs/2.7/deploy/#helm) or [Operator Hub](https://keda.sh/docs/2.7/deploy/#operatorhub). It may have been deployed to your cluster already.

```bash
kubectl apply -f https://github.com/kedacore/keda/releases/download/v2.7.1/keda-2.7.1.yaml
```

Install KEDA HTTP Add-on (via [Helm](https://github.com/kedacore/http-add-on/blob/main/docs/install.md#install-via-helm-chart)). It will be installed in `keda-http` namespace.

```bash
helm upgrade --install http-add-on keda-add-ons-http \
    --repo https://kedacore.github.io/charts \
    --create-namespace \
    --namespace keda-http
```

Install the NGINX Ingress Controller (via [Helm](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start)).

```bash
helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --create-namespace \
    --namespace ingress-nginx
```

Get the IP address of the Ingress Controller.

```bash
SERVICE_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo $SERVICE_IP
```

Clone the [asw101/go-hello](https://github.com/asw101/go-hello) repo locally.

```bash
git clone https://github.com/asw101/go-hello.git
```

Open `go-hello/deploy/kustomization.yaml` and replace the `0.0.0.0` in `hello.0.0.0.0.nip.io` in with the IP address from `$SERVICE_IP` above.

Deploy the manifests in the [go-hello/deploy](https://github.com/asw101/go-hello/tree/main/deploy) folder using kubectl and [kustomization](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/).

```bash
kubectl apply -k go-hello/deploy
```

Output URL and open it in a web browser.

```bash
echo "http://hello.${SERVICE_IP}.nip.io"
```

curl the `/echo` endpoint.

```bash
curl "http://hello.${SERVICE_IP}.nip.io/echo"
```

If you would like to see the pods scale up and down, and/or tail the logs, in real-time, open [k9s](https://github.com/derailed/k9s#installation) in another terminal window and view the `hello` deployment.

Use [hey](https://github.com/rakyll/hey) to generate load against `/wait?ms=450`, which will wait 450ms before responding. This command will use 250 concurrent workers to send a total of 10,000 requests.

```bash
hey -c 250 -n 10000 "http://hello.${SERVICE_IP}.nip.io/wait?ms=450"
```
