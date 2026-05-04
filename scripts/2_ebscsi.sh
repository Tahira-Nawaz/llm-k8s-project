# ============================================
# 1️⃣ Install AWS EBS CSI Driver
# ============================================

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm upgrade --install aws-ebs-csi-driver \
  aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system

echo "⏳ Waiting for EBS CSI pods to be READY..."

# ============================================
# 2️⃣ Wait until pods are READY (True)
# ============================================

NAMESPACE="kube-system"
LABEL="app.kubernetes.io/name=aws-ebs-csi-driver"
TIMEOUT=300
INTERVAL=10
ELAPSED=0

while true; do
  READY=$(kubectl get pods -n $NAMESPACE -l $LABEL \
    -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null)

  if [[ "$READY" == *"false"* || -z "$READY" ]]; then
    echo "❌ Pods not ready yet... waiting"
  else
    echo "✅ All EBS CSI pods are READY"
    break
  fi

  sleep $INTERVAL
  ELAPSED=$((ELAPSED+INTERVAL))

  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "❌ Timeout waiting for EBS CSI pods"
    exit 1
  fi
done

# ============================================
# 3: storageclass
# ============================================

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF

echo "✅ StorageClass created successfully"