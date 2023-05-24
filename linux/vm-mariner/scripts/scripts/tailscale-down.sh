sudo tailscale logout
sudo systemctl stop tailscaled
sudo rm /usr/sbin/tailscale
sudo rm /usr/sbin/tailscaled
sudo rm /etc/systemd/system/tailscaled.service
sudo rm /etc/default/tailscaled
sudo rm -rf /var/lib/tailscale/
sudo systemctl daemon-reload
