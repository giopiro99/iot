#!/bin/bash

# 1. Creiamo il cluster (il nome iot-cluster è opzionale ma pulito)
k3d cluster create iot-cluster

# 2. Spostiamo la configurazione nella cartella VERA dell'utente "vagrant", non in quella di root!
mkdir -p /home/vagrant/.kube
k3d kubeconfig get iot-cluster > /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# 3. Diciamo a questo script dove trovare il file appena creato
export KUBECONFIG=/home/vagrant/.kube/config

# 4. Installiamo Argo CD
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl config set-context --current --namespace=argocd

# 5. Scarichiamo e installiamo la CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# 6. Esponiamo il server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo "Attendo che i componenti di Argo CD siano 'Available'..."
kubectl wait --for=condition=available deployment --all -n argocd --timeout=300s
echo "Attendo la registrazione delle API di Argo CD (CRD)..."
kubectl wait --for=condition=established crd/applications.argoproj.io --timeout=60s

# 8. Ora possiamo applicare in sicurezza il file YAML (dopo aver corretto il doppio namespace!)
kubectl apply -f /vagrant/confs/application.yaml