# Activity 3: Node Group Management

**For:** Workshop Participants  
**Time:** 30 minutes (including 10 min wait)  
**Prerequisites:** Completed [02-NAMESPACE-MANAGEMENT.md](02-NAMESPACE-MANAGEMENT.md)

Learn how to create, scale, and manage worker nodes in the shared EKS cluster.

---

## 🎯 What You'll Learn

- View existing nodes and their details
- Create your own node group
- Scale node groups up and down
- Manage nodes with kubectl (cordon, drain, labels, taints)
- Delete node groups safely

---

## ⚠️ Important: Shared Cluster Warning

Node groups affect **everyone** in the shared cluster!

**Before creating/deleting node groups:**

- 📢 Announce in team chat
- ✅ Wait for acknowledgment
- 🧮 Check cluster capacity first

**NEVER delete the default `training-nodes` node group!**

---

## Understanding Node Groups

**What are Node Groups?**

```
EKS Cluster
├── Control Plane (AWS Managed)
└── Node Groups (You Manage)
    ├── training-nodes (shared, initial group)
    │   ├── Node 1 (EC2 instance)
    │   └── Node 2 (EC2 instance)
    └── charles-nodes (your custom group)
        └── Node 3 (EC2 instance)
```

**Each node (EC2 instance):**

- Runs your pods/containers
- Has CPU, memory, storage
- Can run pods from ANY namespace

---

## Step 1: View Existing Nodes

### List All Nodes

```bash
kubectl get nodes
```

**Expected output:**

```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.ap-southeast-1.compute.internal Ready    <none>   2h    v1.28.x
ip-10-0-2-234.ap-southeast-1.compute.internal Ready    <none>   2h    v1.28.x
```

### View Node Details

```bash
# Detailed view with IPs
kubectl get nodes -o wide

# Full details of a specific node
kubectl describe node ip-10-0-1-123.ap-southeast-1.compute.internal
```

### Check Node Capacity

```bash
# View allocatable resources
kubectl describe nodes | grep -A 5 "Allocatable:"

# Or use top (if metrics-server installed)
kubectl top nodes
```

**Example capacity per node (t3.medium):**

```
Allocatable:
  cpu:     1930m (~1.9 vCPU)
  memory:  3481Mi (~3.4 GB)
  pods:    17
```

### Check Which Pods Run on Each Node

```bash
# Pods on a specific node
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node-name>
```

---

## Step 2: View Node Groups via AWS Console

1. Go to **EKS Console**
2. Click on cluster: **shared-workshop-cluster**
3. Go to **Compute** tab
4. See existing node groups:
   - Name, Status, Instance Type
   - Desired/Min/Max capacity
   - Subnets

### View Node Groups via AWS CLI

```bash
# List all node groups
aws eks list-nodegroups \
    --cluster-name shared-workshop-cluster \
    --region ap-southeast-1

# Describe a node group
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \
    --region ap-southeast-1
```

---

## Step 3: Create Your Own Node Group (Activity!)

Message: "Creating node group charles-nodes (1 node). Will delete after testing."

### Via AWS Console

1. Go to **EKS Console** → **shared-workshop-cluster**
2. Click **Compute** tab → **Add node group**

**Step 1 - Configure node group:**

```
Name: charles-nodes  (use YOUR name!)
Node IAM role: eks-workshop-node-role
```

**Step 2 - Compute configuration:**

```
AMI type: Amazon Linux 2
Capacity type: Spot (saves money!)
Instance types: t3.medium
Disk size: 20 GB

Scaling:
├── Desired: 1
├── Minimum: 0
└── Maximum: 2
```

**Step 3 - Networking:**

```
Subnets: Select BOTH public subnets
Remote access: Not now
```

3. Click **Create**
4. Wait ~5-10 minutes for node to join

### Via AWS CLI

```bash
# Create node group
aws eks create-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --node-role arn:aws:iam::<account-id>:role/eks-workshop-node-role \
    --subnets <subnet-a-id> <subnet-b-id> \
    --instance-types t3.medium \
    --capacity-type SPOT \
    --scaling-config minSize=0,maxSize=2,desiredSize=1 \
    --disk-size 20 \
    --region ap-southeast-1

# Check status
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --region ap-southeast-1 \
    --query 'nodegroup.status'
```

### Verify Your Node Joined

```bash
# Watch for new node
kubectl get nodes -w

# After ~5 minutes, you should see 3 nodes:
# NAME                   STATUS   ROLES    AGE
# ip-10-0-1-xxx          Ready    <none>   2h
# ip-10-0-2-xxx          Ready    <none>   2h
# ip-10-0-1-yyy          Ready    <none>   2m   ← Your new node!
```

---

## Step 4: Scale Node Groups

### Scale via AWS Console

1. EKS Console → Cluster → Compute tab
2. Select your node group
3. Click **Edit**
4. Change **Desired size**
5. Click **Save changes**

### Scale via AWS CLI

```bash
# Scale up to 2 nodes
aws eks update-nodegroup-config \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --scaling-config minSize=0,maxSize=2,desiredSize=2 \
    --region ap-southeast-1

# Scale down to 0 (removes all nodes in group)
aws eks update-nodegroup-config \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --scaling-config minSize=0,maxSize=2,desiredSize=0 \
    --region ap-southeast-1
```

### Monitor Scaling

```bash
# Watch nodes
kubectl get nodes -w

# Check node group status
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --region ap-southeast-1 \
    --query 'nodegroup.[status,scalingConfig]'
```

---

## Step 5: Node Management with kubectl

### Label Nodes

Add labels for scheduling specific pods to specific nodes:

```bash
# Add label
kubectl label nodes <node-name> owner=charles
kubectl label nodes <node-name> environment=testing

# View labels
kubectl get nodes --show-labels

# Remove label (use minus sign)
kubectl label nodes <node-name> owner-
```

### Taint Nodes

Taints prevent pods from scheduling unless they tolerate the taint:

```bash
# Add taint (only pods with matching toleration can run here)
kubectl taint nodes <node-name> dedicated=charles:NoSchedule

# View taints
kubectl describe node <node-name> | grep Taints

# Remove taint (use minus sign)
kubectl taint nodes <node-name> dedicated=charles:NoSchedule-
```

### Cordon Nodes

Prevent new pods from scheduling on a node:

```bash
# Cordon (mark unschedulable)
kubectl cordon <node-name>

# Check status
kubectl get nodes
# Shows: SchedulingDisabled

# Uncordon (allow scheduling again)
kubectl uncordon <node-name>
```

### Drain Nodes

Safely evict all pods from a node:

```bash
# Drain (evict pods and cordon)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# ⚠️ This moves pods to other nodes!
# ⚠️ Only do this for YOUR pods or after announcing!
```

---

## Step 6: Delete Your Node Group

⚠️ **Clean up when done testing!** Don't leave extra nodes running.

### Via AWS Console

1. EKS Console → Cluster → Compute tab
2. Select **charles-nodes** (YOUR node group)
3. Click **Delete**
4. Type node group name to confirm
5. Click **Delete**

### Via AWS CLI

```bash
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --region ap-southeast-1
```

### Verify Deletion

```bash
# Watch nodes disappear
kubectl get nodes -w

# Check node group status
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --region ap-southeast-1 \
    --query 'nodegroup.status'

# Eventually returns error (node group doesn't exist)
```

---

## 🚫 DO NOT Delete the Shared Node Group!

```bash
# ❌ NEVER DO THIS:
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \  # ← NEVER delete this!
    ...

# This removes ALL shared nodes and breaks everyone's workloads!
```

**Only delete node groups YOU created!**

---

## 💰 Cost Awareness

**Node Group Costs:**

```
t3.medium Spot: ~$0.0125/hour (~$9/month)
t3.medium On-Demand: ~$0.0416/hour (~$30/month)

Your 1-node group (Spot): ~$0.0125/hour
Running 4 hours: ~$0.05
```

**Always:**

- Use Spot instances for testing
- Scale to 0 or delete when done
- Don't leave nodes running overnight

---

## ✅ Validation Checklist

- [ ] Viewed existing nodes with `kubectl get nodes`
- [ ] Viewed node details with `kubectl describe node`
- [ ] Created your own node group
- [ ] Verified new node joined cluster
- [ ] Practiced scaling (optional)
- [ ] Practiced labels/taints (optional)
- [ ] **Deleted your node group when done!**

---

## 📋 Quick Commands Reference

```bash
# VIEW nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <name>
kubectl top nodes

# VIEW node groups
aws eks list-nodegroups --cluster-name shared-workshop-cluster --region ap-southeast-1
aws eks describe-nodegroup --cluster-name shared-workshop-cluster --nodegroup-name <name> --region ap-southeast-1

# CREATE node group
aws eks create-nodegroup --cluster-name shared-workshop-cluster --nodegroup-name <your-name>-nodes ...

# SCALE node group
aws eks update-nodegroup-config --cluster-name shared-workshop-cluster --nodegroup-name <name> --scaling-config desiredSize=<n> --region ap-southeast-1

# DELETE node group
aws eks delete-nodegroup --cluster-name shared-workshop-cluster --nodegroup-name <your-name>-nodes --region ap-southeast-1

# NODE operations
kubectl label nodes <name> key=value      # Add label
kubectl label nodes <name> key-           # Remove label
kubectl taint nodes <name> key=value:NoSchedule   # Add taint
kubectl taint nodes <name> key=value:NoSchedule-  # Remove taint
kubectl cordon <name>                     # Mark unschedulable
kubectl uncordon <name>                   # Mark schedulable
kubectl drain <name> --ignore-daemonsets  # Evict pods
```

---

## 🎓 What You Learned

- ✅ How to view nodes and their resources
- ✅ How to create managed node groups
- ✅ How to scale node groups
- ✅ How to manage nodes with kubectl
- ✅ How to clean up node groups
- ✅ Coordination in shared environment

---

## 🚀 Next Activity

Now let's work with container images!

**Next:** [04-ECR-IMAGE-WORKFLOW.md](04-ECR-IMAGE-WORKFLOW.md) - Build, push, and pull Docker images

---

## 📚 Additional Resources

- [Amazon EKS Managed Node Groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [Node Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Node Affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
