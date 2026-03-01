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
apt-get install -y curl

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
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /home/ubuntu/.bashrc

# # Install helm
# curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# # Add Flagger repo and update
# helm repo add flagger https://flagger.app
# helm repo update

# # Install Flagger in namespace flagger-system
# kubectl create namespace flagger-system || true
# helm upgrade --install flagger flagger/flagger \
#   --namespace flagger-system \
#   --create-namespace \
#   --set meshProvider=traefik \
#   --set metricsServer=http://prometheus-service.sre-demo:9090

echo "===== Wait for cluster ====="
sleep 30

echo "===== Install Git ====="
apt install -y git

echo "===== Clone Repository ====="
cd /home/ubuntu

if [ ! -d "order-api-sre" ]; then
  git clone https://github.com/funCodeSonali/order-api-sre.git
fi

cd order-api-sre/k8s

echo "===== Deploy Namespace ====="
kubectl apply -f 00-namespace.yaml

sleep 5

echo "===== Deploy Application ====="
kubectl apply -f app/order-api-deployment.yaml
kubectl apply -f app/order-api-service.yaml

echo "===== Deploy Monitoring Stack ====="
kubectl apply -f monitoring/

echo "===== Deploy Middleware ====="
kubectl apply -f middleware.yaml

echo "===== Deploy Ingress ====="
kubectl apply -f ingress/

echo "===== Final Pod Status ====="
kubectl get pods -n sre-demo

echo "===== Bootstrap Complete ====="
