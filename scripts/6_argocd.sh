#!/bin/bash

set -e

echo "🚀 Creating namespace..."
kubectl create namespace argocd || true

echo "📦 Adding Helm repo..."
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

echo "📝 Creating values file..."
cat <<EOF > argocd-values.yaml
server:
  extraArgs:
    - --insecure

  service:
    type: ClusterIP

  ingress:
    enabled: false

  config:
    url: https://argocd.llm-k8s.awssolutionsprovider.com

repoServer:
  replicas: 1

controller:
  replicas: 1

dex:
  enabled: true
EOF

echo "⚙️ Installing Argo CD..."
helm install argocd argo/argo-cd \
  -n argocd \
  -f argocd-values.yaml

echo "⏳ Waiting for Argo CD pods..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s || true

echo "🌐 Creating HTTPRoute for Traefik..."

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: argocd-route
  namespace: argocd
spec:
  parentRefs:
    - name: traefik-wild
      namespace: traefik
  hostnames:
    - "argocd.llm-k8s.awssolutionsprovider.com"
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

echo "🔧 Patching Argo CD for insecure mode..."
kubectl -n argocd patch deployment argocd-server \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"argocd-server","args":["--insecure"]}]}}}}' || true

echo "✅ DONE!"
echo "🌍 Access URL: https://argocd.llm-k8s.awssolutionsprovider.com"