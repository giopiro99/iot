#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "avvio script per installare docker"
# Add Docker's official GPG key:
apt-get update -y
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update -y 

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# altra soluzione per risolvere il problema spiegato nel file get-argo.sh
# echo "copio il file daemon.json per configurare il dns di docker in modo che non si incastri"
# cp /vagrant/confs/daemon.json /etc/docker/daemon.json
# sudo systemctl restart docker

echo "script per installare docker terminato correttamente"
