#!/bin/bash

echo "avvio script per scaricare k3d"

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "installo la CLI kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "k3d e kubectl installati correttamente"
