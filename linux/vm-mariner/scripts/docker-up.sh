sudo tdnf install moby-engine moby-cli ca-certificates -y
sudo systemctl enable docker.service
sudo systemctl daemon-reload
sudo systemctl start docker.service
