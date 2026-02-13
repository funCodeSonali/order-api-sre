#!/bin/bash
set -e

echo "===== Create Swap if using burstable instance type====="
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo "Swap created successfully."

echo "===== System Update ====="
apt update -y

echo "===== Install Docker ====="
apt install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

echo "===== Install k3s (Kubernetes) ====="
curl -sfL https://get.k3s.io | sh -

echo "===== Configure kubeconfig ====="
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
chmod 644 /etc/rancher/k3s/k3s.yaml

# Install Traefik CRDs
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml

echo "===== Wait for cluster ====="
sleep 30

# echo "===== Install Helm ====="
# curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# echo "===== Add Helm Repo ====="
# helm repo add traefik https://traefik.github.io/charts
# helm repo update

# echo "===== Install Traefik Ingress ====="
# helm install traefik traefik/traefik \
#   --namespace kube-system \
#   --create-namespace \
#   --kubeconfig /etc/rancher/k3s/k3s.yaml

echo "===== Install Git ====="
apt install -y git

echo "===== Clone Repository ====="
cd /home/ubuntu

git clone https://github.com/funCodeSonali/order-api-sre.git

cd order-api-sre/k8s

echo "===== Deploy Namespace ====="
kubectl apply -f 00-namespace.yaml

sleep 5

echo "===== Deploy Application ====="
kubectl apply -f app/

echo "===== Deploy Monitoring Stack ====="
kubectl apply -f monitoring/

echo "===== Deploy Middleware ====="
kubectl apply -f middleware.yaml

echo "===== Deploy Ingress ====="
kubectl apply -f ingress.yaml

echo "===== Final Pod Status ====="
kubectl get pods -n sre-demo

echo "===== Bootstrap Complete ====="
