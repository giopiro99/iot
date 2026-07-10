#!/bin/bash

echo "configurazione kubernetes in modalita' server.."

# --node-ip=assegna al nodo un ip che decidiamo noi
# --flannel-iface=enp0s8 forza ad utilizzare la scheda di rete giusta correlata a quell ip
# --disable=metrics-server disabilita configurazioni che non ci servonon per evitare problemi legati alla ram
curl -sfL https://get.k3s.io \
    | INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --token ${K3S_CLUSTER_TOKEN} --flannel-iface=enp0s8 --disable=traefik --disable=metrics-server" \
        sh -s -


echo "configurazione kubernetes in modalita' server terminata.."