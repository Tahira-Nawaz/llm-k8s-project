#!/bin/bash
set -e

# =====================================================

# BASE DOMAIN CONFIG

# =====================================================

BASE_DOMAIN="llm-k8s-tahira.awssolutionsprovider.com"
WILDCARD_DOMAIN="*.${BASE_DOMAIN}"

echo "🌍 Base Domain: $BASE_DOMAIN"
echo "🔐 Wildcard: $WILDCARD_DOMAIN"

# =====================================================

# 1. TRAEFIK NAMESPACE

# =====================================================

kubectl create namespace traefik || true

# =====================================================

# 2. CREATE WILDCARD CERTIFICATE

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

# 3. WAIT FOR CERTIFICATE

# =====================================================

echo "⏳ Waiting for certificate to be READY..."

while true; do
STATUS=$(kubectl get certificate -n traefik traefik-tls 
-o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | tr -d '[:space:]')

if [[ "$STATUS" == "True" ]]; then
echo "✅ Certificate is READY"
break
fi

echo "⏳ Still waiting..."
sleep 10
done

# =====================================================

# 4. CREATE GATEWAY

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
tls:
mode: Terminate
certificateRefs:
- name: traefik-tls
allowedRoutes:
namespaces:
from: All
EOF

echo "🌟 Gateway + TLS setup completed!"
