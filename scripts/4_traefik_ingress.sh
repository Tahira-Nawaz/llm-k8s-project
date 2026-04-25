


#!/bin/bash

echo "🚀 Installing Traefik with Ingress + Gateway API..."

# Add Helm repo
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Create values1.yaml
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

# Install / Upgrade Traefik
helm upgrade --install traefik traefik/traefik \
  -n kube-system \
  --create-namespace \
  -f values1.yaml

echo "⏳ Waiting for Traefik rollout..."
kubectl rollout status deployment traefik -n kube-system

echo "🌐 Traefik Service:"
kubectl get svc -n kube-system traefik

echo "✅ Traefik installed with Ingress + Gateway API!"


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
# namespace
# -----------------------------

kubectl create ns traefik
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
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: traefik-wild
  namespace: traefik
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod1" # Your ClusterIssuer name
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
      certificateRefs:
      - name: nginx-tls1
    
EOF
# -----------------------------
# Httproute
# -----------------------------
kubectl apply -f - <<EOF
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
          namespace: traefik1
          port: 80
EOF
