#!/bin/bash

set -e

# =====================================================
# BASE DOMAIN CONFIGURATION
# =====================================================
BASE_DOMAIN="llm-k8s1.awssolutionsprovider.com"
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
  name: wildcard-cert
  namespace: traefik
spec:
  secretName: wildcard-tls
  dnsNames:
    - "${WILDCARD_DOMAIN}"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-route53
EOF

# =====================================================
# 3. CERTIFICATE WAIT LOOP (IMPROVED)
# =====================================================
echo "⏳ Waiting for wildcard certificate to be READY..."

CERT_NAME="wildcard-cert"
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
          - name: wildcard-tls
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

# =====================================================
# 8. INSTALL ARGOCD
# =====================================================
echo "⚙️ Installing ArgoCD..."

helm upgrade --install argocd argo/argo-cd \
  -n argocd \
  --create-namespace \
  -f argocd-values.yaml

# =====================================================
# 9. WAIT PODS
# =====================================================
kubectl wait --for=condition=Ready pod \
  -n argocd --all --timeout=600s

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
    - "${ARGOCD_DOMAIN}"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: argocd-server
          namespace: argocd
          port: 80
EOF

# =====================================================
# 11. WAIT API
# =====================================================
echo "⏳ Waiting for ArgoCD API..."

until curl -k https://${ARGOCD_DOMAIN}/api/version >/dev/null 2>&1; do
  echo "Waiting..."
  sleep 10
done

# =====================================================
# 12. ARGOCD CLI INSTALL
# =====================================================
echo "💻 Installing ArgoCD CLI..."

curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# =====================================================
# 13. LOGIN
# =====================================================
echo "🔑 Getting admin password..."

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d)

echo "🌐 Logging into ArgoCD..."

argocd login "${ARGOCD_DOMAIN}" \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --insecure

argocd version

echo "🚀 DONE! ArgoCD is fully ready at https://${ARGOCD_DOMAIN}"