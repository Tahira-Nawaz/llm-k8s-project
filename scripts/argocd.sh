#!/bin/bash

set -e

# =====================================================
# BASE DOMAIN CONFIGURATION
# =====================================================
BASE_DOMAIN="llm-k8s-dev.awssolutionsprovider.com"
ARGOCD_DOMAIN="argocd.${BASE_DOMAIN}"
WILDCARD_DOMAIN="*.${BASE_DOMAIN}"

echo "🌍 Base Domain: $BASE_DOMAIN"
echo "🔐 Wildcard: $WILDCARD_DOMAIN"
echo "🚀 ArgoCD: $ARGOCD_DOMAIN"

# =====================================================
# 1. TRAEFIK NAMESPACE
# =====================================================
kubectl create namespace traefik || true

# =====================================================
# 2. WILDCARD CERTIFICATE
# =====================================================
echo "🔐 Creating wildcard certificate..."

cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: traefik-tls
  namespace: traefik
spec:
  secretName: traefik-tls
  dnsNames:
    - "${WILDCARD_DOMAIN}"

  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-route53
EOF

# =====================================================
# 3. CERTIFICATE WAIT LOOP (IMPROVED)
# =====================================================
echo "⏳ Waiting for traefik-tls certificate to be READY..."

CERT_NAME="traefik-tls"
NAMESPACE="traefik"
MAX_RETRIES=30
SLEEP=10

for ((i=1; i<=MAX_RETRIES; i++)); do
  STATUS=$(kubectl get certificate -n "$NAMESPACE" "$CERT_NAME" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | tr -d '[:space:]')

  if [[ "$STATUS" == "True" ]]; then
    echo "✅ Certificate is READY"
    break
  fi

  echo "❌ Not ready yet... attempt $i/$MAX_RETRIES"
  sleep $SLEEP
done

# =====================================================
# 4. GATEWAY
# =====================================================
echo "🚪 Creating Gateway..."

cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: traefik
  namespace: traefik
spec:
  gatewayClassName: traefik
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: "${WILDCARD_DOMAIN}"
      tls:
        mode: Terminate
        certificateRefs:
          - name: traefik-tls
      allowedRoutes:
        namespaces:
          from: All
EOF

# =====================================================
# 5. ARGOCD NAMESPACE
# =====================================================
kubectl create namespace argocd || true

# =====================================================
# 6. HELM REPO
# =====================================================
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

# =====================================================
# 7. ARGOCD VALUES
# =====================================================
cat <<EOF > argocd-values.yaml
server:
  replicas: 1
  extraArgs:
    - --insecure

  service:
    type: ClusterIP

  ingress:
    enabled: false

  config:
    url: https://${ARGOCD_DOMAIN}

controller:
  replicas: 1

repoServer:
  replicas: 1

applicationSet:
  replicas: 1

dex:
  enabled: true
EOF

# ======================================
# Step 8: Install or Upgrade Argo CD
# ======================================
echo "🚀 Installing or upgrading Argo CD..."
helm upgrade --install argocd argo/argo-cd \
  -f argocd-values.yaml \
  -n argocd \
  --create-namespace

# ======================================
# Step 9: Wait for Argo CD Pods to be Ready
# ======================================
echo "⏳ Waiting for Argo CD pods to become available..."
kubectl wait --for=condition=available --timeout=600s deployment -l app.kubernetes.io/part-of=argocd -n argocd

# =====================================================
# 10. HTTPROUTE
# =====================================================
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: argocd-route
  namespace: argocd
spec:
  parentRefs:
    - name: traefik
      namespace: traefik
  hostnames:
    - ${ARGOCD_DOMAIN}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: argocd-server
          namespace: argocd
          port: 443
EOF

# ======================================
# Step 11: Display Argo CD Pods
# ======================================
echo "📋 Argo CD Pods:"
kubectl get pods -n argocd
kubectl -n argocd patch deployment argocd-server \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'
# ======================================
# Step 12: Retrieve Initial Admin Password
# ======================================
echo "🔑 Initial Argo CD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# ======================================
# Step 13: Install Argo CD CLI
# ======================================
echo "💻 Installing Argo CD CLI..."
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# ======================================
# Step 14: Login to Argo CD via CLI
# ======================================
ARGOCD_SERVER="$ARGOCD_DOMAIN"

echo "📦 Getting Argo CD admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)

echo "🌐 Logging in to Argo CD server at $ARGOCD_SERVER ..."

argocd login "$ARGOCD_SERVER" \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --grpc-web \
  --insecure

echo "📊 Argo CD Version:"
argocd version

echo "🌟 Argo CD login successful for ${ARGOCD_DOMAIN}"