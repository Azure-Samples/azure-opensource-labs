#!bin/bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes=10.1.0.0/24,168.63.129.16/32 --accept-dns=false --ssh --authkey "${tailscale_auth_key}"