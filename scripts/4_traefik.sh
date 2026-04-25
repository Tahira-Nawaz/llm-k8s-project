#!/bin/bash

set -e

echo "🚀 Installing Traefik..."

# -----------------------------
# Helm repo
# -----------------------------
helm repo add traefik https://traefik.github.io/charts
helm repo update

# -----------------------------
# Single Namespace
# -----------------------------
kubectl create ns traefik || true

# -----------------------------
# Traefik values
# -----------------------------
cat <<EOF > values.yaml
api:
  dashboard: true
  insecure: false

deployment:
  replicas: 2

providers:
  kubernetesIngress:
    enabled: true

  kubernetesGateway:
    enabled: true

gateway:
  enabled: true

gatewayClass:
  enabled: true

ingressClass:
  enabled: true
  name: traefik

ports:
  web:
    port: 80
    expose:
      default: true
    exposedPort: 80

  websecure:
    port: 443
    expose:
      default: true
    exposedPort: 443

service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
EOF

echo "📝 values.yaml created"

# -----------------------------
# Install Traefik
# -----------------------------
helm upgrade --install traefik traefik/traefik \
  -n traefik \
  --create-namespace \
  -f values.yaml

echo "⏳ Waiting for Traefik rollout..."
kubectl rollout status deployment traefik -n traefik

kubectl get svc -n traefik

echo "✅ Traefik installed"


# -----------------------------
# ClusterIssuer (cert-manager)
# -----------------------------
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod1
spec:
  acme:
    email: tnawaz@puffersoft.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod1
    solvers:
      - http01:
          ingress:
            class: traefik
EOF

echo "✅ ClusterIssuer created"


# -----------------------------
# App Deployment
# -----------------------------
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
EOF


# -----------------------------
# Service
# -----------------------------
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-test
  namespace: traefik
spec:
  selector:
    app: nginx-test
  ports:
    - port: 80
      targetPort: 80
EOF


# -----------------------------
# Gateway
# -----------------------------
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: traefik-wild
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "*.llm-k8s.awssolutionsprovider.com"
      allowedRoutes:
        namespaces:
          from: All
      tls:
        mode: Terminate
EOF

echo "✅ Gateway created"


# -----------------------------
# HTTPRoute
# -----------------------------
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: nginx-route-wild
  namespace: traefik
spec:
  parentRefs:
    - name: traefik-wild
      namespace: traefik
  hostnames:
    - "test.llm-k8s.awssolutionsprovider.com"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: nginx-test
          port: 80
EOF

echo "🎯 HTTPRoute created"

echo "🚀 Setup completed successfully"