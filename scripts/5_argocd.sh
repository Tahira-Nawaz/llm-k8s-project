#!/bin/bash

set -e

# =====================================================
# 1. Domain Configuration
# =====================================================
DOMAIN="argocd.llm-k8s.awssolutionsprovider.com"

# =====================================================
# 2. Namespace Creation
# =====================================================
echo "🚀 Creating namespace..."
kubectl create namespace argocd || true

# =====================================================
# 3. Helm Repository Setup
# =====================================================
echo "📦 Adding Helm repo..."
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

# =====================================================
# 4. Argo CD Values File Creation
# =====================================================
echo "📝 Creating values file..."
cat <<EOF > argocd-values1.yaml
server:
  replicas: 2
  extraArgs:
    - --insecure

  service:
    type: ClusterIP

  ingress:
    enabled: false

  config:
    url: https://${DOMAIN}

controller:
  replicas: 1

repoServer:
  replicas: 2

applicationSet:
  replicas: 2

dex:
  enabled: true
EOF

# =====================================================
# 5. Install / Upgrade Argo CD
# =====================================================
echo "⚙️ Installing or Upgrading Argo CD..."
helm upgrade --install argocd argo/argo-cd \
  -n argocd \
  --create-namespace \
  -f argocd-values1.yaml

# =====================================================
# 6. Wait for Pods to be Ready
# =====================================================
echo "⏳ Waiting for Argo CD pods..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s || true

# =====================================================
# 7. Traefik HTTPRoute Configuration
# =====================================================
echo "🌐 Creating HTTPRoute for Traefik..."
kubectl apply -f - <<EOF
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
    - "${DOMAIN}"
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
# 8. Patch Argo CD (Insecure Mode)
# =====================================================
echo "🔧 Patching Argo CD for insecure mode..."
kubectl -n argocd patch deployment argocd-server \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"argocd-server","args":["--insecure"]}]}}}}' || true

# =====================================================
# 9. Access Information
# =====================================================
echo "✅ DONE!"
echo "🌍 Access URL: https://${DOMAIN}"

# =====================================================
# 10. Retrieve Admin Password
# =====================================================
echo "🔑 Initial Argo CD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# =====================================================
# 11. Install Argo CD CLI
# =====================================================
echo "💻 Installing Argo CD CLI..."
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# =====================================================
# 12. Login to Argo CD CLI
# =====================================================
ARGOCD_SERVER="${DOMAIN}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)

echo "🌐 Logging in to Argo CD server at $ARGOCD_SERVER ..."
argocd login "$ARGOCD_SERVER" \
  --username admin \
  --password "$ARGOCD_PASSWORD" \
  --grpc-web \
  --insecure

argocd version

echo "🌟 Argo CD installation and login successful for ${DOMAIN}."