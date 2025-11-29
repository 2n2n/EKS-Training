# Persistent Volumes - Deep Dive

Welcome to the storage deep dive! Learn how Kubernetes abstracts storage and provides persistent data for your applications.

---

## 🎯 Learning Objectives

By the end of this guide, you will:

- ✅ Understand the Kubernetes storage architecture
- ✅ Work with StorageClasses, PVs, and PVCs
- ✅ Use dynamic vs static provisioning
- ✅ Understand access modes and reclaim policies
- ✅ Implement volume snapshots and backups
- ✅ Troubleshoot storage issues

---

## ⏱️ Time Estimate

**Total Time: 35-40 minutes**

- Understanding concepts: 10 min
- Dynamic provisioning: 10 min
- Static provisioning: 10 min
- Snapshots and backups: 10 min

---

## 📋 Prerequisites

- Cluster running (preferably EKS)
- kubectl configured
- Understanding of Pods and StatefulSets
- EBS CSI driver installed (for EKS)

---

## Kubernetes Storage Architecture

### The Three-Layer Model

```
Storage Abstraction Layers:

1. StorageClass
   ├── Defines types of storage available
   ├── Created by: Cluster admin
   └── Examples: fast-ssd, slow-hdd, efs-shared

2. PersistentVolume (PV)
   ├── Actual storage resource
   ├── Created by: Admin (static) or StorageClass (dynamic)
   └── Examples: AWS EBS volume, NFS share

3. PersistentVolumeClaim (PVC)
   ├── Request for storage
   ├── Created by: Developer/User
   └── Binds to a PV that matches requirements
```

### 🏢 Traditional Storage Management

```bash
# Traditional: Direct disk management

# 1. Attach physical disk
fdisk /dev/sdb

# 2. Create filesystem
mkfs.ext4 /dev/sdb1

# 3. Mount
mount /dev/sdb1 /var/lib/mysql

# 4. Configure fstab
echo "/dev/sdb1 /var/lib/mysql ext4 defaults 0 0" >> /etc/fstab

Problems:
❌ Manual process
❌ Server-specific
❌ Not portable
❌ Hard to manage at scale
```

### ☁️ Kubernetes Storage

```yaml
# Developer just requests storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-data
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi

# Kubernetes handles:
✅ Provisioning EBS volume
✅ Formatting
✅ Attaching to node
✅ Mounting to pod
✅ Cleanup when done
```

---

## Lab 1: Exploring StorageClasses

### Step 1: List Available StorageClasses

```bash
# View storage classes
kubectl get storageclass

# Typical EKS output:
# NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE
# gp2             ebs.csi.aws.com         Delete          WaitForFirstConsumer
# gp3 (default)   ebs.csi.aws.com         Delete          WaitForFirstConsumer
```

### Step 2: Examine a StorageClass

```bash
# View default storage class details
kubectl describe storageclass gp3

# Or as YAML
kubectl get storageclass gp3 -o yaml
```

### Step 3: Create Custom StorageClass

```bash
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "5000"
  throughput: "250"
  encrypted: "true"
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
EOF
```

**Parameters Explained:**
- `type: gp3`: AWS EBS volume type (gp3 is latest, cheapest)
- `iops: "5000"`: I/O operations per second
- `throughput: "250"`: MB/s throughput
- `encrypted: "true"`: Encrypt data at rest
- `allowVolumeExpansion: true`: Allow resizing without recreation
- `volumeBindingMode`: When to provision volume
  - `Immediate`: Create volume immediately
  - `WaitForFirstConsumer`: Wait until pod uses it (better for zone placement)
- `reclaimPolicy`:
  - `Delete`: Delete volume when PVC deleted
  - `Retain`: Keep volume for manual recovery

---

## Lab 2: Dynamic Provisioning (Most Common)

### Step 1: Create a PersistentVolumeClaim

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 5Gi
EOF
```

### Step 2: Watch Dynamic Provisioning

```bash
# Initially: Pending (no pod using it yet)
kubectl get pvc dynamic-pvc

# Check events
kubectl describe pvc dynamic-pvc

# After pod creation (next step), becomes: Bound
```

### Step 3: Use PVC in a Pod

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:1.25
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: dynamic-pvc
EOF
```

### Step 4: Verify Volume Provisioned

```bash
# PVC should now be Bound
kubectl get pvc dynamic-pvc

# Check PV that was created
kubectl get pv

# See AWS EBS volume ID
kubectl get pv <pv-name> -o yaml | grep volumeHandle

# The volumeHandle is the actual AWS EBS volume ID
```

### Step 5: Write Data to Volume

```bash
# Wait for pod
kubectl wait --for=condition=ready pod/app-with-storage --timeout=60s

# Write data
kubectl exec app-with-storage -- sh -c "echo 'Persistent data!' > /usr/share/nginx/html/index.html"

# Read data
kubectl exec app-with-storage -- cat /usr/share/nginx/html/index.html
```

### Step 6: Test Persistence

```bash
# Delete pod
kubectl delete pod app-with-storage

# Recreate pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:1.25
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: dynamic-pvc
EOF

# Wait for pod
kubectl wait --for=condition=ready pod/app-with-storage --timeout=60s

# Data is still there!
kubectl exec app-with-storage -- cat /usr/share/nginx/html/index.html
```

---

## Lab 3: Access Modes

### Understanding Access Modes

```
Access Modes (EBS):

ReadWriteOnce (RWO):
├── One node can mount as read-write
├── Supported by: EBS, most block storage
└── Use: Databases, single-pod applications

ReadOnlyMany (ROX):
├── Multiple nodes can mount as read-only
├── Supported by: NFS, EFS
└── Use: Shared configuration, static content

ReadWriteMany (RWX):
├── Multiple nodes can mount as read-write
├── Supported by: NFS, EFS (not EBS!)
└── Use: Shared file systems, logs

⚠️ EBS only supports ReadWriteOnce!
```

### Test ReadWriteOnce Limitation

```bash
# Create PVC with RWO
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rwo-test
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
EOF

# Create Deployment with 2 replicas
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rwo-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: rwo-test
  template:
    metadata:
      labels:
        app: rwo-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: rwo-test
EOF

# Check pod status
kubectl get pods -l app=rwo-test

# If pods on different nodes, one will be stuck:
# - One pod Running (on node with volume)
# - One pod Pending (can't mount on different node)

kubectl describe pod <pending-pod-name>
# Error: Volume is already attached to another node
```

---

## Lab 4: Volume Expansion

### Step 1: Create Expandable PVC

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: expandable-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gp3  # Must support expansion
  resources:
    requests:
      storage: 1Gi
EOF
```

### Step 2: Create Pod Using PVC

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-expansion
spec:
  containers:
  - name: app
    image: busybox:1.35
    command: ["/bin/sh", "-c", "df -h /data; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: expandable-pvc
EOF
```

### Step 3: Check Initial Size

```bash
kubectl wait --for=condition=ready pod/test-expansion --timeout=60s
kubectl logs test-expansion

# Should show 1Gi volume
```

### Step 4: Expand the Volume

```bash
# Edit PVC to increase size
kubectl patch pvc expandable-pvc -p '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'

# Watch expansion
kubectl get pvc expandable-pvc -w

# PVC status goes through:
# 1. FileSystemResizePending
# 2. Resizing (EBS volume expanded)
# 3. Bound (filesystem resized)
```

### Step 5: Verify New Size

```bash
# Restart pod to see new size (or wait for automatic resize)
kubectl delete pod test-expansion
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-expansion
spec:
  containers:
  - name: app
    image: busybox:1.35
    command: ["/bin/sh", "-c", "df -h /data; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: expandable-pvc
EOF

kubectl logs test-expansion
# Should now show 5Gi volume
```

---

## Lab 5: Volume Snapshots (Backups)

### Step 1: Verify VolumeSnapshot CRDs

```bash
# Check if VolumeSnapshot API is available
kubectl api-resources | grep volumesnapshot

# Should see:
# volumesnapshotclasses
# volumesnapshotcontents
# volumesnapshots
```

### Step 2: Create VolumeSnapshotClass

```bash
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: ebs-snapshot-class
driver: ebs.csi.aws.com
deletionPolicy: Delete
EOF
```

### Step 3: Create Data to Backup

```bash
# Create PVC and pod with data
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-test
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
spec:
  containers:
  - name: app
    image: busybox:1.35
    command: ["/bin/sh", "-c", "echo 'Important data!' > /data/file.txt; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: backup-test
EOF

# Wait for pod
kubectl wait --for=condition=ready pod/data-pod --timeout=60s

# Verify data
kubectl exec data-pod -- cat /data/file.txt
```

### Step 4: Create Snapshot (Backup)

```bash
cat <<EOF | kubectl apply -f -
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: backup-snapshot
spec:
  volumeSnapshotClassName: ebs-snapshot-class
  source:
    persistentVolumeClaimName: backup-test
EOF

# Watch snapshot creation
kubectl get volumesnapshot backup-snapshot -w

# Check when ready
kubectl describe volumesnapshot backup-snapshot
```

### Step 5: Simulate Data Loss

```bash
# Delete data
kubectl exec data-pod -- rm /data/file.txt

# Verify data gone
kubectl exec data-pod -- ls /data/
```

### Step 6: Restore from Snapshot

```bash
# Create new PVC from snapshot
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: restored-data
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
  dataSource:
    name: backup-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF

# Create pod using restored data
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: restored-pod
spec:
  containers:
  - name: app
    image: busybox:1.35
    command: ["/bin/sh", "-c", "cat /data/file.txt; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: restored-data
EOF

# Verify data restored
kubectl logs restored-pod
# Should show: Important data!
```

---

## Lab 6: Static Provisioning (Advanced)

### When to Use Static Provisioning

```
Use static provisioning when:
├── Pre-existing volumes need to be used
├── Specific volume configuration required
├── Manual control over storage placement
└── Integration with external storage systems
```

### Step 1: Manually Create AWS EBS Volume

```bash
# Get cluster's availability zone
AZ=$(kubectl get nodes -o jsonpath='{.items[0].metadata.labels.topology\.kubernetes\.io/zone}')

# Create EBS volume
VOLUME_ID=$(aws ec2 create-volume \
  --availability-zone $AZ \
  --size 5 \
  --volume-type gp3 \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=static-pv-volume}]' \
  --query 'VolumeId' \
  --output text)

echo "Created volume: $VOLUME_ID"

# Wait for volume to be available
aws ec2 wait volume-available --volume-ids $VOLUME_ID
```

### Step 2: Create PersistentVolume

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  csi:
    driver: ebs.csi.aws.com
    volumeHandle: $VOLUME_ID
EOF
```

### Step 3: Create Matching PVC

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 5Gi
EOF
```

### Step 4: Verify Binding

```bash
# PV and PVC should bind to each other
kubectl get pv static-pv
kubectl get pvc static-pvc

# Both should show Status: Bound
```

---

## 💡 Best Practices

### Storage Planning

```yaml
1. Right-size volumes
   # Request what you need, plan for growth
   # Expansion is possible but not shrinking
   
2. Use appropriate storage class
   gp3: General purpose (default)
   io2: High IOPS (databases)
   st1: Throughput optimized (big data)

3. Enable encryption
   parameters:
     encrypted: "true"

4. Set proper reclaim policy
   Retain: For production data (manual cleanup)
   Delete: For test/dev (automatic cleanup)

5. Use volume snapshots
   # Regular backups
   # Test restore procedures
```

### Performance Optimization

```yaml
1. Use gp3 over gp2
   # 20% cheaper
   # Better baseline performance
   # Configurable IOPS/throughput

2. Right-size IOPS
   parameters:
     iops: "3000"  # Baseline is 3000
     throughput: "125"  # MB/s

3. Use WaitForFirstConsumer
   volumeBindingMode: WaitForFirstConsumer
   # Better for multi-AZ clusters
   # Volume created in same AZ as pod

4. Monitor usage
   # AWS CloudWatch metrics
   # Kubernetes metrics-server
   # Resize if needed
```

---

## 🔍 Troubleshooting

### PVC Stuck in Pending

```bash
# Check PVC events
kubectl describe pvc <pvc-name>

# Common causes:
# - No matching StorageClass
# - Insufficient capacity
# - Zone constraints
# - Quota exceeded

# Check StorageClass exists
kubectl get storageclass

# Check EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi
```

### Volume Won't Mount

```bash
# Check pod events
kubectl describe pod <pod-name>

# Common causes:
# - Volume already attached to another node
# - Filesystem errors
# - Node capacity issues

# Check volume attachment
kubectl get volumeattachment
```

### Can't Delete PVC

```bash
# Check if pod is still using it
kubectl describe pvc <pvc-name>

# Delete pod first
kubectl delete pod <pod-name>

# Then delete PVC
kubectl delete pvc <pvc-name>

# If stuck with finalizer
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'
```

---

## 🧹 Cleanup

```bash
# Delete pods
kubectl delete pod app-with-storage data-pod restored-pod test-expansion

# Delete deployments
kubectl delete deployment rwo-test

# Delete PVCs (this deletes PVs and EBS volumes)
kubectl delete pvc dynamic-pvc expandable-pvc backup-test restored-data rwo-test static-pvc

# Delete static PV manually
kubectl delete pv static-pv

# Delete AWS EBS volume (for static volume)
aws ec2 delete-volume --volume-id $VOLUME_ID

# Delete snapshot
kubectl delete volumesnapshot backup-snapshot

# Delete custom resources
kubectl delete storageclass fast-ssd
kubectl delete volumesnapshotclass ebs-snapshot-class
```

---

## 📊 Storage Comparison

### EBS vs EFS

| Feature | EBS | EFS |
|---------|-----|-----|
| **Access Mode** | ReadWriteOnce | ReadWriteMany |
| **Performance** | High IOPS | Lower latency |
| **Cost** | $0.08/GB/month | $0.30/GB/month |
| **Use Case** | Databases | Shared files |
| **Scaling** | Manual | Automatic |

### Storage Class Types

| Type | Use Case | IOPS | Throughput | Cost |
|------|----------|------|------------|------|
| **gp3** | General purpose | 3,000-16,000 | 125-1,000 MB/s | $ |
| **gp2** | General purpose | 3-16,000 | 250 MB/s | $$ |
| **io2** | High performance | Up to 64,000 | 1,000 MB/s | $$$ |
| **st1** | Throughput optimized | 500 | 500 MB/s | $ |
| **sc1** | Cold storage | 250 | 250 MB/s | $ (lowest) |

---

## 📚 Additional Resources

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Snapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/)
- [EBS CSI Driver](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [AWS EBS Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)

---

## ✅ Knowledge Check

You should now be able to:

- [ ] Understand Kubernetes storage architecture
- [ ] Create and use StorageClasses
- [ ] Work with dynamic and static provisioning
- [ ] Understand access modes
- [ ] Expand volumes
- [ ] Create and restore from snapshots
- [ ] Troubleshoot storage issues

---

## 🚀 Congratulations!

You've completed **Part A: Kubernetes Workloads**!

You now understand:
- ✅ Jobs and CronJobs for batch processing
- ✅ Secrets and ConfigMaps for configuration
- ✅ StatefulSets for stateful applications
- ✅ Persistent Volumes for data persistence

---

## What's Next?

**Continue to Activity 5, Part B:** Networking and Services
- ClusterIP, NodePort, LoadBalancer
- DNS and service discovery
- Application Load Balancer (ALB)
- Auto-scaling (HPA and Cluster Autoscaler)

**Then Activity 5, Part C:** CI/CD Pipeline
- Jenkins setup
- Automated deployments
- ECR integration
- Complete GitOps workflow

---

**Amazing work!** You've mastered Kubernetes storage! 💾🎉

