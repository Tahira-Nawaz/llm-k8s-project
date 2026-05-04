#!/bin/bash
set -e

# =====================================================
# DOMAIN CONFIG
# =====================================================

BASE_DOMAIN="llm-k8s-tahira.awssolutionsprovider.com"
ARGOCD_DOMAIN="argocd.${BASE_DOMAIN}"

echo "🚀 ArgoCD Domain: $ARGOCD_DOMAIN"

# =====================================================
# 1. NAMESPACE
# =====================================================

kubectl create namespace argocd || true

# =====================================================
# 2. HELM SETUP
# =====================================================

helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

# =====================================================
# 3. VALUES FILE (FIXED YAML)
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
# 4. INSTALL ARGOCD (FIXED LINE BREAKS)
# =====================================================

echo "🚀 Installing Argo CD..."

helm upgrade --install argocd argo/argo-cd \
  -f argocd-values.yaml \
  -n argocd \
  --create-namespace

# =====================================================
# 5. WAIT FOR PODS (FIXED)
# =====================================================

echo "⏳ Waiting for Argo CD pods..."

kubectl wait --for=condition=available --timeout=600s \
  deployment -l app.kubernetes.io/part-of=argocd -n argocd

# =====================================================
# 6. CREATE HTTPROUTE (FIXED INDENTATION)
# =====================================================

echo "🌐 Creating HTTPRoute..."

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
          port: 80
EOF

# =====================================================
# 7. GET PASSWORD
# =====================================================

echo "🔑 Getting admin password..."

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo "$ARGOCD_PASSWORD"

# =====================================================
# 8. INSTALL CLI
# =====================================================

echo "💻 Installing Argo CD CLI..."

curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# =====================================================
# 9. LOGIN
# =====================================================

echo "🌐 Logging into Argo CD..."

argocd login "$ARGOCD_DOMAIN" \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --grpc-web \
  --insecure

echo "📊 Version:"
argocd version

echo "🌟 Argo CD ready: https://${ARGOCD_DOMAIN}"