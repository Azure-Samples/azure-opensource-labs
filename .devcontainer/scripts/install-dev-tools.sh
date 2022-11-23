#!/bin/sh

# install kubectl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl bash-completion
# source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
# echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.
# alias k=kubectl
# complete -o default -F __start_kubectl k

# install k6
K6_VERSION=v0.41.0
curl -sL "https://github.com/grafana/k6/releases/download/$K6_VERSION/k6-$K6_VERSION-linux-amd64.tar.gz" | tar -vxzf -
sudo mv ./k6-$K6_VERSION-linux-amd64/k6 /usr/local/bin/k6
rm -Rf ./k6-$K6_VERSION-linux-amd64

# install osm
OSM_VERSION=v1.2.0
curl -sL "https://github.com/openservicemesh/osm/releases/download/$OSM_VERSION/osm-$OSM_VERSION-linux-amd64.tar.gz" | tar -vxzf -
sudo mv ./linux-amd64/osm /usr/local/bin/osm
rm -Rf ./linux-amd64