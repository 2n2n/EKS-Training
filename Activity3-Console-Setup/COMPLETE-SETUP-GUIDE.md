# Activity 3: Complete Console Setup Guide

**Consolidated guide for creating EKS cluster via AWS Console**

This guide combines all setup steps into one document. For detailed explanations, refer to individual numbered guides.

---

## ⏱️ Total Time: 3-4 hours

- **Active work:** ~2.5 hours
- **Wait time:** ~30 minutes
- **Cleanup:** ~30 minutes

---

## 🎯 What You'll Create

1. VPC with 2 public subnets
2. Security groups for cluster and nodes
3. IAM roles (cluster and node)
4. EKS cluster
5. Managed node group
6. Todo application deployment

---

## Step 1: VPC Setup (30 min)

### Create VPC

1. Go to **VPC Console** → **Your VPCs** → **Create VPC**
2. Settings:
   - Name: `eks-training-vpc`
   - IPv4 CIDR: `10.0.0.0/16`
   - IPv6: No
   - Tenancy: Default
3. **Create VPC**
4. Note the VPC ID

### Create Subnets

**Subnet A:**
1. **Subnets** → **Create subnet**
2. VPC: Select `eks-training-vpc`
3. Settings:
   - Name: `eks-training-public-a`
   - AZ: `ap-southeast-1a`
   - IPv4 CIDR: `10.0.1.0/24`
4. **Create subnet**

**Subnet B:**
1. **Create subnet**
2. VPC: Select `eks-training-vpc`
3. Settings:
   - Name: `eks-training-public-b`
   - AZ: `ap-southeast-1b`
   - IPv4 CIDR: `10.0.2.0/24`
4. **Create subnet**

**Enable auto-assign public IP:**
1. Select each subnet
2. **Actions** → **Edit subnet settings**
3. Check **Enable auto-assign public IPv4 address**
4. **Save**

### Create Internet Gateway

1. **Internet Gateways** → **Create internet gateway**
2. Name: `eks-training-igw`
3. **Create**
4. **Actions** → **Attach to VPC**
5. Select `eks-training-vpc`
6. **Attach**

### Configure Route Table

1. **Route Tables** → Find table for your VPC
2. **Edit routes** → **Add route**
3. Settings:
   - Destination: `0.0.0.0/0`
   - Target: Select your Internet Gateway
4. **Save changes**
5. **Subnet associations** → **Edit subnet associations**
6. Select both public subnets
7. **Save associations**

### Create Security Groups

**Cluster Security Group:**
1. **Security Groups** → **Create security group**
2. Settings:
   - Name: `eks-training-cluster-sg`
   - Description: "EKS cluster security group"
   - VPC: `eks-training-vpc`
3. **Inbound rules:** (None needed initially)
4. **Outbound rules:** All traffic
5. **Create**

**Node Security Group:**
1. **Create security group**
2. Settings:
   - Name: `eks-training-node-sg`
   - Description: "EKS node security group"
   - VPC: `eks-training-vpc`
3. **Inbound rules:**
   - Type: All traffic, Source: `eks-training-node-sg` (self)
   - Type: Custom TCP, Port: 30000-32767, Source: 0.0.0.0/0
4. **Outbound rules:** All traffic
5. **Create**

---

## Step 2: IAM Roles (20 min)

### Create Cluster Role

1. Go to **IAM Console** → **Roles** → **Create role**
2. Trusted entity type: **AWS service**
3. Use case: **EKS** → **EKS - Cluster**
4. **Next**
5. Policy `AmazonEKSClusterPolicy` should be selected
6. **Next**
7. Role name: `eks-training-cluster-role`
8. **Create role**

### Create Node Role

1. **Create role**
2. Trusted entity: **AWS service**
3. Use case: **EC2**
4. **Next**
5. Attach policies:
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonEC2ContainerRegistryReadOnly`
6. **Next**
7. Role name: `eks-training-node-role`
8. **Create role**

---

## Step 3: Create EKS Cluster (30 min + 20 min wait)

1. Go to **EKS Console** → **Clusters** → **Add cluster** → **Create**
2. **Configure cluster:**
   - Name: `training-cluster`
   - Version: Latest (1.28 or higher)
   - Cluster service role: `eks-training-cluster-role`
3. **Next**
4. **Specify networking:**
   - VPC: `eks-training-vpc`
   - Subnets: Select both public subnets
   - Security groups: `eks-training-cluster-sg`
   - Cluster endpoint access: Public
5. **Next**
6. **Configure logging:** (Optional - increases cost)
   - Enable: API server, Audit
   - Or skip for cost savings
7. **Next**
8. **Review and create**
9. **Create**

**Wait ~20 minutes** for cluster to become ACTIVE

### Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name training-cluster --region ap-southeast-1

# Verify connection
kubectl get svc

# Should see: kubernetes ClusterIP service
```

---

## Step 4: Create Node Group (20 min + 10 min wait)

1. In **EKS Console**, select `training-cluster`
2. **Compute** tab → **Add node group**
3. **Configure node group:**
   - Name: `training-nodes`
   - Node IAM role: `eks-training-node-role`
4. **Next**
5. **Set compute and scaling configuration:**
   - AMI type: Amazon Linux 2
   - Capacity type: **Spot**
   - Instance types: `t3.medium`
   - Disk size: 20 GB
   - Desired size: 2
   - Minimum size: 2
   - Maximum size: 2
6. **Next**
7. **Specify networking:**
   - Subnets: Select both public subnets
   - SSH access: None (or configure if needed)
8. **Next**
9. **Review and create**
10. **Create**

**Wait ~10 minutes** for nodes to become Ready

### Verify Nodes

```bash
# Check nodes
kubectl get nodes

# Should see 2 nodes with STATUS=Ready

# Check system pods
kubectl get pods -n kube-system

# All pods should be Running
```

---

## Step 5: Deploy Todo Application (40 min)

### Create Deployment YAML

Create `todo-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
  labels:
    app: todo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo
  template:
    metadata:
      labels:
        app: todo
    spec:
      containers:
      - name: todo
        image: nginx:alpine  # Replace with your Todo app image
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: todo-service
spec:
  type: NodePort
  selector:
    app: todo
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

### Deploy Application

```bash
# Apply deployment
kubectl apply -f todo-deployment.yaml

# Wait for pods to be ready
kubectl get pods -w

# Check service
kubectl get service todo-service

# Get node public IPs
kubectl get nodes -o wide
```

### Access Application

```bash
# Get node public IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# Access application
echo "Access app at: http://$NODE_IP:30080"

# Or in browser:
# http://node-public-ip:30080
```

---

## Step 6: Testing (20 min)

### Verify Deployment

```bash
# Check pods
kubectl get pods -l app=todo
# Should see 2 pods Running

# Check pods distribution
kubectl get pods -o wide
# Should see pods on different nodes

# Describe pod
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Check service
kubectl get svc todo-service
# Should see NodePort type with port 30080
```

### Test High Availability

```bash
# Delete one pod
kubectl delete pod <pod-name>

# Watch recreation
kubectl get pods -w
# New pod should be created automatically

# App should still be accessible during this
```

### Test Scaling

```bash
# Scale up
kubectl scale deployment todo-app --replicas=4

# Watch pods
kubectl get pods -w

# Scale down
kubectl scale deployment todo-app --replicas=2
```

---

## Step 7: CLEANUP (30 min)

**⚠️ CRITICAL: Delete everything to stop charges!**

### Delete Application

```bash
# Delete deployment and service
kubectl delete -f todo-deployment.yaml

# Verify deletion
kubectl get all
```

### Delete Node Group

1. EKS Console → `training-cluster`
2. **Compute** tab
3. Select `training-nodes`
4. **Delete**
5. Type node group name to confirm
6. **Delete**
7. **Wait ~10 minutes**

### Delete EKS Cluster

1. EKS Console → **Clusters**
2. Select `training-cluster`
3. **Delete cluster**
4. Type cluster name to confirm
5. **Delete**
6. **Wait ~10-15 minutes**

### Delete VPC Resources

**Delete Security Groups:**
1. VPC Console → **Security Groups**
2. Select `eks-training-node-sg`
3. **Actions** → **Delete security groups**
4. Select `eks-training-cluster-sg`
5. **Delete**

**Detach and Delete Internet Gateway:**
1. **Internet Gateways**
2. Select `eks-training-igw`
3. **Actions** → **Detach from VPC**
4. **Actions** → **Delete internet gateway**

**Delete Subnets:**
1. **Subnets**
2. Select both `eks-training-public-a` and `eks-training-public-b`
3. **Actions** → **Delete subnet**

**Delete VPC:**
1. **Your VPCs**
2. Select `eks-training-vpc`
3. **Actions** → **Delete VPC**

### Delete IAM Roles

1. IAM Console → **Roles**
2. Select `eks-training-cluster-role`
3. **Delete**
4. Select `eks-training-node-role`
5. **Delete**

### Verify Cleanup

```bash
# No EKS clusters
aws eks list-clusters --region ap-southeast-1
# Should return empty

# No running EC2 instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --region ap-southeast-1
# Should return empty

# No VPCs (except default)
aws ec2 describe-vpcs --region ap-southeast-1
# Should only see default VPC

# Check billing
# AWS Console → Billing → Bills
# Verify no ongoing charges
```

---

## 🚨 Common Issues

### Cluster Creation Fails

**Check:**
- IAM role has correct trust relationship
- VPC has at least 2 subnets in different AZs
- Subnets have available IPs

**View details:**
```bash
aws eks describe-cluster --name training-cluster --region ap-southeast-1
```

### Nodes Not Joining

**Check:**
- Node role has all required policies
- Security group allows traffic
- Subnets have internet access (route to IGW)

**View node logs:**
```bash
kubectl describe node <node-name>
kubectl logs -n kube-system -l k8s-app=aws-node
```

### Can't Access Application

**Check:**
- Security group allows port 30080
- Service type is NodePort
- Pods are Running

**Get service details:**
```bash
kubectl describe service todo-service
kubectl get pods -l app=todo
```

---

## ✅ Success Checklist

- [ ] VPC and subnets created
- [ ] Security groups configured
- [ ] IAM roles created
- [ ] EKS cluster ACTIVE
- [ ] 2 nodes Ready
- [ ] Application deployed
- [ ] Application accessible via browser
- [ ] **Everything deleted**
- [ ] **No ongoing AWS charges**

---

## 💰 Cost Reminder

While cluster is running:
- **Per hour:** ~$0.13
- **Per day:** ~$3.15
- **Per month:** ~$95

**Always delete when done!**

---

## 🚀 What's Next?

Congratulations! You've manually created an EKS cluster and understand all components.

**Next:** [../Activity4-Scripted-Setup/README.md](../Activity4-Scripted-Setup/README.md)

See how eksctl automates this entire process in one command!

---

**Remember:** The manual way teaches you the details. The automated way (Activity 4) is how you'll actually work with EKS! 🎓

