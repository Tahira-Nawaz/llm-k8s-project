# ======================================
# 1️⃣ Install prerequisites and Helm repo setup
# ======================================

sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

helm repo add jetstack https://charts.jetstack.io


# ======================================
# 2️⃣ Install cert-manager
# ======================================

echo "📦 Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true

echo "⏳ Waiting for cert-manager pods to be ready..."
kubectl wait --for=condition=Ready --timeout=600s -n cert-manager --all pods


# ======================================
# 3️⃣ Create ClusterIssuer for Let's Encrypt
# ======================================

echo "📝 Creating ClusterIssuer letsencrypt-prod..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-route53
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: mkhalid@puffersoft.com
    privateKeySecretRef:
      name: letsencrypt-route53-account-key
    solvers:
      - dns01:
          route53:
            region: us-west-2
            hostedZoneID: Z02745981J3FQC8Y0Z4P7
EOF


# ======================================
# 4️⃣ Verify cert-manager installation
# ======================================

echo "🔍 Checking cert-manager pods..."
kubectl get pods -n cert-manager

echo "🔍 Checking ClusterIssuer..."
kubectl get clusterissuer