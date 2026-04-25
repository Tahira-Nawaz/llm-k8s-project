sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list



helm repo add jetstack https://charts.jetstack.io

# ======================================
# Step 3: Install cert-manager
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
# Step 4: Create ClusterIssuer for Let's Encrypt
# ======================================
echo "📝 Creating ClusterIssuer letsencrypt-prod..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: tnawaz@puffersoft.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
EOF