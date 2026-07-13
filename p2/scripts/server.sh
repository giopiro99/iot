#!/bin/bash

curl -sfL https://get.k3s.io \
    | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --token ${K3S_CLUSTER_TOKEN} --flannel-iface=enp0s8 --disable=metrics-server" \
        sh -s -

until nc -zv 192.168.56.110 6443 &> /dev/null 2>&1; do
    echo "attendo che kubernetes abbia finito l installazione"
    sleep 5
done

sudo kubectl apply -f /var/k3s/
