#!/bin/bash

echo "configurazione kubernetes in modalita' agent.."

# aspetto che il server sia pronto e in ascolto sulla porta 6443
# uso nc perche' lavora a livello tcp(non http come curl) e non richiede autenticazione
# -z => non invia nessun dato, fa l handshake tcp e chiude la connessione
# &> cattura l output di nc e lo butta in /dev/null
# /dev/null => tutto cio' che va la dentro viene eliminato
# 2>&1 serve per buttare anche lo stderror nello stesso post di stdout ovvero /dev/null
# il ciclo dura finche' nc non ritorna 0 (successo)
until nc -zv 192.168.56.110 6443 &> /dev/null 2>&1; do
    echo "Aspetto il Master..."
    sleep 5
done

echo "DEBUG-AGENT: Il token ricevuto da Vagrant è: '${K3S_CLUSTER_TOKEN}'"

curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC="agent --server https://192.168.56.110:6443 --node-ip 192.168.56.111 --flannel-iface=enp0s8 --token ${K3S_CLUSTER_TOKEN}" \
        sh -s -

echo "configurazione kubernetes in modalita' agent terminata.."
