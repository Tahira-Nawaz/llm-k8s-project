#!/bin/bash

# =====================================================
# Namespace Variable
# =====================================================
NAMESPACE="kube-system"

echo "🚀 Installing Traefik in namespace: $NAMESPACE"

# =====================================================
# Add Helm Repository
# =====================================================
helm repo add traefik https://traefik.github.io/charts
helm repo update

# =====================================================
# Create Helm Values File
# =====================================================
cat <<EOF > values1.yaml
api:
  dashboard: true
  insecure: false

deployment:
  replicas: 2

gateway:
  enabled: true

gatewayClass:
  enabled: true

ingressClass:
  enabled: true
  name: traefik

providers:
  kubernetesIngress:
    enabled: true

  kubernetesGateway:
    enabled: true

ports:
  traefik:
    port: 8000
    expose:
      default: false

  web:
    port: 80
    exposedPort: 80
    expose:
      default: true
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true

  websecure:
    port: 443
    exposedPort: 443
    expose:
      default: true

service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
EOF

echo "📝 values1.yaml created"

# =====================================================
# Install / Upgrade Traefik
# =====================================================
helm upgrade --install traefik traefik/traefik \
  -n $NAMESPACE \
  --create-namespace \
  -f values1.yaml

echo "⏳ Waiting for Traefik rollout..."
kubectl rollout status deployment traefik -n $NAMESPACE

echo "✅ Traefik installed successfully!"

# =====================================================
# Wait for LoadBalancer DNS
# =====================================================
DNS=""

while [ -z "$DNS" ] || [ "$DNS" == "<pending>" ]; do
  DNS=$(kubectl get svc traefik -n $NAMESPACE \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  echo "Waiting for LB DNS..."
  sleep 5
done

echo "✅ Traefik LoadBalancer DNS: $DNS"

# =====================================================
# Show Service
# =====================================================
kubectl get svc traefik -n $NAMESPACE