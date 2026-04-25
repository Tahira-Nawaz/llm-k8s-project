# Configure kubectl for the master node
sudo mkdir -p ~/.kube
sudo cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin
sudo cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
sudo chmod 644 ~/.kube/config

# Configure kubectl for the local user (if required, specify the user)
sudo mkdir -p /home/ubuntu/.kube
sudo cp /etc/rancher/rke2/rke2.yaml /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo chmod 644 /home/ubuntu/.kube/config

# ============================================
# 0️⃣ Helm Installation (Prerequisite)
# ============================================

sudo apt-get update
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash



# ============================================
# 1️⃣ Add Helm Repositories (AWS / EKS)
# ============================================

helm repo add eks https://aws.github.io/eks-charts
helm repo update


# ============================================
# 2️⃣ Install AWS Load Balancer Controller
# ============================================

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=default

