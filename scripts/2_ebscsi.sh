# ============================================
# 3️⃣ Install AWS EBS CSI Driver
# ============================================

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm upgrade --install aws-ebs-csi-driver \
  aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system

kubectl get pods -n kube-system | grep ebs