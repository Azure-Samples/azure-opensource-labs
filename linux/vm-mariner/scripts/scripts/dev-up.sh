# install vim, jq, postgresql, ...
dnf install -y vim jq postgresql

# install go manually
[[ -z "${GO_VERSION:-}" ]] && GO_VERSION='1.20.4'
[[ "$(uname -m)" == "aarch64" ]] && GO_ARCH='arm64'
[[ "$(uname -m)" == "x86_64" ]] && GO_ARCH='amd64'
[[ -z "${GO_ARCH:-}" ]] && GO_ARCH='amd64'

GO_NAME="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
curl -L -o "${GO_NAME}" "https://go.dev/dl/${GO_NAME}"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "${GO_NAME}"
rm "${GO_NAME}"

STRING='export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin'
touch $FILE
grep -q -F "$STRING" "$FILE" || echo $STRING | tee -a $FILE && source $FILE

# install mage
go install github.com/magefile/mage@latest
