# Configure kubectl for the master node
sudo mkdir -p ~/.kube
sudo cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin
sudo cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
sudo chmod 644 ~/.kube/config

# ============================================
# 1️⃣ Helm Installation (Prerequisite)
# ============================================

sudo apt-get install curl gpg apt-transport-https --yes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm version

# ============================================
# 2️⃣ Add Helm Repositories (AWS / EKS)
# ============================================

helm repo add eks https://aws.github.io/eks-charts
helm repo update

# ============================================
# 3️⃣ Install AWS Load Balancer Controller
# ============================================

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=default

# ============================================
# 4️⃣ Verify Installation
# ============================================

echo "Checking deployment..."
kubectl get deployment -n kube-system | grep aws-load-balancer

echo "Checking pods..."
kubectl get pods -n kube-system | grep aws-load-balancer

echo "⏳ Waiting until pods are READY..."

for i in {1..30}; do
  STATUS=$(kubectl get pods -n kube-system \
    -l app.kubernetes.io/name=aws-load-balancer-controller \
    -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null)

  if [[ "$STATUS" == *"false"* || -z "$STATUS" ]]; then
    echo "❌ Not ready yet... retry $i"
    sleep 10
  else
    echo "✅ All pods are READY (True)"
    break
  fi
done