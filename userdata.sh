#!/bin/bash
set -e

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

echo "===== Wait for cluster ====="
sleep 30

echo "===== Install Git ====="
apt install -y git

echo "===== Clone Repository ====="
cd /home/ubuntu

git clone https://github.com/funCodeSonali/order-api-sre.git

cd order-api-sre/k8

echo "===== Deploy Namespace ====="
kubectl apply -f 00-namespace.yaml

sleep 5

echo "===== Deploy Application ====="
kubectl apply -f app/

echo "===== Deploy Monitoring Stack ====="
kubectl apply -f monitoring/

echo "===== Deploy Ingress ====="
kubectl apply -f ingress.yaml

echo "===== Final Pod Status ====="
kubectl get pods -n sre-demo

echo "===== Bootstrap Complete ====="
