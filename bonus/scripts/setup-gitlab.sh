#!/bin/bash

CONFS_PATH=/vagrant/confs
ENV_PATH=/vagrant/scripts
set -e

if [ -f "$ENV_PATH"/.env ]; then
    export $(cat "$ENV_PATH"/.env | grep -v '^#' | xargs)
else
    echo "Errore: File .env non trovato!"
    exit 1
fi

set +e

kubectl create namespace gitlab

echo "install bitnami"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

##NB il database si DEVE chiamare gitlabhq_production con username gitlab
echo "creo il secret per postgres.."
  kubectl create secret generic postgres-credentials \
  --namespace gitlab \
  --from-literal=postgresql-password="$POSTGRES_PASSWORD" \
  --from-literal=postgresql-username="$POSTGRES_USERNAME" \
  --from-literal=postgresql-postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=password="$GITLAB_DB_PASSWORD"

echo "installo postgress.."
helm upgrade --install my-postgres bitnami/postgresql \
  -n gitlab \
  -f "$CONFS_PATH"/postgres-values.yaml \
  --set auth.username="$POSTGRES_USERNAME" \
  --set auth.database="$POSTGRES_DATABASE" \
  --set auth.password="$GITLAB_DB_PASSWORD"

echo "creo il secret per redis.."
kubectl create secret generic redis-credentials \
  --namespace gitlab \
  --from-literal=redis-password="$REDIS_PASSWORD"

echo "installo redis.."
helm upgrade --install redis bitnami/redis \
  -n gitlab \
  -f "$CONFS_PATH"/redis-values.yaml

echo "Genero minio-values.yaml dal template..."
cp "$CONFS_PATH"/minio-values.template.yaml "$CONFS_PATH"/minio-values.yaml
sed -i "s|__MINIO_USER__|$MINIO_ACCESS_KEY|g" "$CONFS_PATH"/minio-values.yaml
sed -i "s|__MINIO_PASSWORD__|$MINIO_SECRET_KEY|g" "$CONFS_PATH"/minio-values.yaml

helm repo add minio https://charts.min.io/
helm repo update
helm upgrade --install my-minio minio/minio -n gitlab -f "$CONFS_PATH"/minio-values.yaml

kubectl create secret generic s3-connection-secret \
  --from-file=connection="$CONFS_PATH"/s3-connection.yaml \
  --namespace gitlab

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm search repo gitlab

helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f "$CONFS_PATH"/gitlab-values.yaml
