cd /home/azureuser/

TS_VERSION='1.40.1'
TS_ARCH='amd64'
TS_NAME="tailscale_${TS_VERSION}_${TS_ARCH}"

curl -L -o "${TS_NAME}.tgz" "https://pkgs.tailscale.com/stable/${TS_NAME}.tgz"

tar -xvf "${TS_NAME}.tgz"
rm "${TS_NAME}.tgz"
rm -rf tmp/
mv "${TS_NAME}" tmp/

sudo mv tmp/tailscale tmp/tailscaled /usr/sbin/
sudo mv tmp/systemd/tailscaled.service /etc/systemd/system/
sudo mv tmp/systemd/tailscaled.defaults /etc/default/tailscaled
rm -rf tmp/

sudo systemctl start tailscaled

# export TS_AUTHKEY='...'
sudo tailscale login --auth-key="${TS_AUTHKEY}"
sudo tailscale up --ssh --hostname=mariner-vm1
