curl -OL https://go.dev/dl/go1.21.0.linux-amd64.tar.gz

rm -rf $HOME/go && tar -C $HOME -xzf go1.21.0.linux-amd64.tar.gz

rm go1.21.0.linux-amd64.tar.gz

export PATH=$PATH:/home/azureuser/go/bin

go install github.com/magefile/mage@latest
