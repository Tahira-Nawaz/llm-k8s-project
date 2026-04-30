#!/bin/bash

# =====================================================
# 1. Domain Configuration
# =====================================================
DOMAIN="llm-k8s1.awssolutionsprovider.com"

# =====================================================
# 2. Traefik Installation Start
# =====================================================
echo "🚀 Installing Traefik with Ingress + Gateway API..."

# =====================================================
# 3. Add Helm Repository
# =====================================================
helm repo add traefik https://traefik.github.io/charts
helm repo update

# =====================================================
# 4. Create Helm Values File
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
# 5. Install / Upgrade Traefik
# =====================================================
helm upgrade --install traefik traefik/traefik \
  -n traefik1 \
  --create-namespace \
  -f values1.yaml

echo "⏳ Waiting for Traefik rollout..."
kubectl rollout status deployment traefik -n kube-system

echo "✅ Traefik installed successfully!"


echo "⏳ Waiting for LoadBalancer DNS..."

DNS=""
while [ -z "$DNS" ] || [ "$DNS" == "<pending>" ]; do
  DNS=$(kubectl get svc traefik -n traefik1 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  echo "Waiting for LB DNS..."
  sleep 5
done

echo "✅ Traefik LoadBalancer DNS: $DNS"

# =====================================================
# 6. Create Namespace
# =====================================================
kubectl create ns traefik || true

# =====================================================
# 7. Create TLS Certificate
# =====================================================
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: traefik-tls
  namespace: traefik
spec:
  secretName: traefik-tls
  dnsNames:
    - "*.${DOMAIN}"

  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-route53
EOF

echo "⏳ Waiting 40 seconds before checking status..."
sleep 40

echo "⏳ Waiting for Certificate to be Ready..."
CERT_NAME="traefik-tls"
NAMESPACE="traefik"
MAX_RETRIES=10
RETRY_INTERVAL=10

for ((i=1; i<=MAX_RETRIES; i++)); do
  STATUS=$(kubectl get certificate -n "$NAMESPACE" "$CERT_NAME" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | tr -d '[:space:]')

  if [[ "$STATUS" == "True" ]]; then
    echo "✅ Certificate '$CERT_NAME' is ready (attempt $i)"
    break
  else
    echo "❌ Not ready yet (attempt $i/$MAX_RETRIES). Waiting $RETRY_INTERVAL seconds..."
    sleep "$RETRY_INTERVAL"
  fi
done
# =====================================================
# 8. Check Certificate Status
# =====================================================
kubectl wait --for=condition=Ready certificate/traefik-tls -n traefik --timeout=300s

echo "🔐 Certificate is Ready!"

# =====================================================
# 9. Create Gateway
# =====================================================
kubectl apply -f - <<EOF
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
      hostname: "*.${DOMAIN}"
      tls:
        mode: Terminate
        certificateRefs:
          - name: traefik-tls
      allowedRoutes:
        namespaces:
          from: All
        kinds:
          - kind: HTTPRoute
          - kind: GRPCRoute
EOF


# =====================================================
# 10. Verification
# =====================================================

echo "🌐 Traefik Service:"
kubectl get svc -n kube-system traefik

echo "🔐 Certificate Status:"
kubectl get certificate -n traefik

echo "🚪 Gateway Status:"
kubectl get gateway -n traefik
