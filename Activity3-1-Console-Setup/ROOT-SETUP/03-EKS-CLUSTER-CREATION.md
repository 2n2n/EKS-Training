# Root Setup 03: EKS Cluster Creation

**For:** Workshop Administrator (Root Account)  
**Time:** 30 minutes active + 20 minutes wait = 50 minutes total  
**Cost Impact:** $0.10/hour ($2.40/day) for control plane

Create the shared EKS cluster that all 7 participants will use.

---

## 🎯 What You'll Create

- 1× EKS Cluster (shared by all participants)
- Control plane with Kubernetes API server
- Multi-AZ highly available architecture
- Public endpoint access for kubectl

---

## 📋 Prerequisites

- [ ] Completed [01-VPC-AND-NETWORKING.md](01-VPC-AND-NETWORKING.md)
- [ ] Completed [02-IAM-ROLES.md](02-IAM-ROLES.md)
- [ ] Have VPC ID, Subnet IDs, Security Group IDs ready
- [ ] Have Cluster Role ARN ready

---

## Step 1: Gather Required Information

Before starting, collect these IDs from previous steps:

```
VPC ID: vpc-xxxxxxxxxxxxx
Subnet A ID: subnet-xxxxxxxxxxxxx (ap-southeast-1a)
Subnet B ID: subnet-xxxxxxxxxxxxx (ap-southeast-1b)
Cluster Security Group ID: sg-xxxxxxxxxxxxx
Cluster Role ARN: arn:aws:iam::<account-id>:role/eks-workshop-cluster-role
```

---

## Step 2: Create EKS Cluster via Console (10 min)

### Navigate to EKS

1. Go to **EKS Console**: https://console.aws.amazon.com/eks/
2. Ensure you're in **ap-southeast-1** region (top-right)
3. Click **Add cluster** → **Create**

### Configure Cluster (Step 1/5)

```
Name: shared-workshop-cluster
Kubernetes version: 1.28 (or latest available)
Cluster service role: eks-workshop-cluster-role
```

**Tags (Optional but recommended):**

```
Key: Project, Value: EKS-Workshop
Key: Environment, Value: Training
Key: ManagedBy, Value: Root
```

Click **Next**

### Specify Networking (Step 2/5)

```
VPC: eks-workshop-vpc (select from dropdown)

Subnets: Select BOTH:
☑ eks-workshop-public-a (ap-southeast-1a)
☑ eks-workshop-public-b (ap-southeast-1b)

Security groups:
☑ eks-workshop-cluster-sg

Cluster endpoint access:
○ Public and private (recommended for workshop)
```

**Advanced settings:**

```
Cluster IP address family: IPv4
```

Click **Next**

### Configure Observability (Step 3/5)

**Control Plane Logging (Optional - adds cost):**

For workshop, you can:

- **Option A (No logging):** Uncheck all (saves money, ~$1-2/month)
- **Option B (Basic logging):** Check only:
  - ☑ API server
  - ☑ Audit

**Prometheus metrics:** Leave unchecked (saves cost)

Click **Next**

### Select Add-ons (Step 4/5)

Keep the default add-ons (all checked):

- ☑ Amazon VPC CNI
- ☑ kube-proxy
- ☑ CoreDNS

**Version:** Use latest available for each

Click **Next**

### Configure Selected Add-ons (Step 5/5)

Keep all settings at defaults:

- Configuration values: Default
- Conflict resolution method: Overwrite

Click **Next**

### Review and Create

1. Review all settings carefully
2. Ensure cluster name is correct: `shared-workshop-cluster`
3. Ensure 2 subnets selected
4. Ensure correct IAM role
5. Click **Create**

---

## Step 3: Wait for Cluster Creation (20 min)

**Status will progress:**

```
Creating → Active (takes ~15-20 minutes)
```

**What's happening behind the scenes:**

- AWS provisions control plane across multiple AZs
- Sets up API server, scheduler, controller manager
- Creates etcd database (3 replicas)
- Configures networking and security
- Creates CloudFormation stack
- Provisions elastic network interfaces (ENIs)

**While waiting, you can:**

- Read the next guide (04-INITIAL-NODE-GROUP.md)
- Review participant guides
- Prepare to grant access to participants

**Monitor progress:**

- Refresh the EKS console page
- Status indicator will change from "Creating" to "Active"
- Usually takes 15-20 minutes

---

## Step 4: Verify Cluster Creation

Once status shows **Active**:

### Via AWS Console

1. Click on cluster name: **shared-workshop-cluster**
2. Verify these details:

```
Overview tab:
├── Status: Active ✅
├── Kubernetes version: 1.28 (or your selected version)
├── API server endpoint: https://xxxxx.eks.ap-southeast-1.amazonaws.com
├── Cluster ARN: arn:aws:eks:ap-southeast-1:xxx:cluster/shared-workshop-cluster
└── Created: (timestamp)

Networking tab:
├── VPC ID: vpc-xxxxx (eks-workshop-vpc)
├── Subnets: 2 subnets in different AZs
├── Security groups: sg-xxxxx (eks-workshop-cluster-sg)
└── Endpoint access: Public and private

Configuration tab:
├── Cluster IAM role: eks-workshop-cluster-role
├── Add-ons: VPC-CNI, kube-proxy, CoreDNS (all active)
└── Control plane logging: (your selection)
```

### Via AWS CLI

```bash
# Describe the cluster
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.[name,status,version,endpoint]' \
    --output table

# Get detailed cluster info
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 > cluster-details.json

# Check status
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.status' \
    --output text

# Should return: ACTIVE
```

---

## Step 5: Configure kubectl Access (5 min)

Now connect your local kubectl to the cluster.

### Update kubeconfig

```bash
# Update kubeconfig with cluster credentials
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1

# Expected output:
# Added new context arn:aws:eks:ap-southeast-1:xxx:cluster/shared-workshop-cluster to /Users/xxx/.kube/config
```

### Verify Connection

```bash
# Test connection
kubectl get svc

# Expected output:
# NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
# kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   5m

# Get cluster info
kubectl cluster-info

# Expected output shows:
# Kubernetes control plane is running at https://xxxxx.eks.ap-southeast-1.amazonaws.com
```

### Check Cluster Components

```bash
# View cluster version
kubectl version --short

# Check nodes (should be none yet - that's expected!)
kubectl get nodes

# Expected output:
# No resources found

# Check namespaces
kubectl get namespaces

# Expected output:
# NAME              STATUS   AGE
# default           Active   5m
# kube-node-lease   Active   5m
# kube-public       Active   5m
# kube-system       Active   5m
```

---

## ✅ Validation Checklist

- [ ] Cluster status shows **Active** in console
- [ ] Cluster has API endpoint URL
- [ ] 2 subnets attached (different AZs)
- [ ] Cluster role is eks-workshop-cluster-role
- [ ] kubectl connection works
- [ ] `kubectl get svc` shows kubernetes service
- [ ] `kubectl get namespaces` shows 4 system namespaces
- [ ] No errors in cluster events

---

## 📝 Save Cluster Information

Document these for participants:

```bash
# Get cluster details
echo "Cluster Name: shared-workshop-cluster"
echo "Region: ap-southeast-1"

echo "API Endpoint:"
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.endpoint' \
    --output text

echo "Cluster ARN:"
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.arn' \
    --output text

echo "Kubernetes Version:"
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.version' \
    --output text
```

Save to file:

```
Cluster Name: shared-workshop-cluster
Region: ap-southeast-1
API Endpoint: https://xxxxx.eks.ap-southeast-1.amazonaws.com
Cluster ARN: arn:aws:eks:ap-southeast-1:xxx:cluster/shared-workshop-cluster
Kubernetes Version: 1.28
Created: 2024-12-03
```

---

## 🚨 Troubleshooting

### Issue: Cluster Stuck in "Creating"

**If stuck for >30 minutes:**

1. Check CloudFormation for errors:

```bash
# List CloudFormation stacks
aws cloudformation list-stacks \
    --stack-status-filter CREATE_IN_PROGRESS CREATE_FAILED \
    --region ap-southeast-1 \
    --query 'StackSummaries[?contains(StackName, `eks`)].{Name:StackName,Status:StackStatus}' \
    --output table
```

2. Check cluster events:

```bash
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.health' \
    --output json
```

3. Common causes:
   - IAM role doesn't have required permissions
   - Subnets don't have available IPs
   - Security group misconfigured
   - Service limits reached

---

### Issue: Creation Failed

**Error:** "Cannot create cluster"

**Possible causes and solutions:**

**IAM Role Issues:**

```bash
# Verify role exists and has correct trust policy
aws iam get-role --role-name eks-workshop-cluster-role

# Check attached policies
aws iam list-attached-role-policies --role-name eks-workshop-cluster-role
# Should show: AmazonEKSClusterPolicy
```

**Subnet Issues:**

```bash
# Check subnets have available IPs
aws ec2 describe-subnets \
    --subnet-ids <subnet-a-id> <subnet-b-id> \
    --query 'Subnets[].[SubnetId,AvailableIpAddressCount]' \
    --output table

# Should each have >5 available IPs
```

**Service Quotas:**

```bash
# Check EKS cluster limit
aws service-quotas get-service-quota \
    --service-code eks \
    --quota-code L-1194D53C \
    --region ap-southeast-1

# Default limit is 100 clusters per region
```

---

### Issue: Can't Connect with kubectl

**Error:** "Unable to connect to the server"

**Solution 1: Check AWS credentials**

```bash
aws sts get-caller-identity
# Verify you're using correct account/user
```

**Solution 2: Re-run update-kubeconfig**

```bash
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --verbose
```

**Solution 3: Check cluster is Active**

```bash
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.status' \
    --output text
```

---

### Issue: kubectl Shows "Unauthorized"

**Error:** "error: You must be logged in to the server (Unauthorized)"

**Solution:**

```bash
# Check your AWS identity
aws sts get-caller-identity

# The IAM user/role that created the cluster has automatic admin access
# Other users need to be added to aws-auth ConfigMap (done in step 06)

# For now, only cluster creator can access
```

---

## 💰 Cost Tracking

### Current Costs

**After cluster creation:**

```
EKS Control Plane:
├── $0.10/hour
├── $2.40/day
└── $72/month

Total so far: $0.10/hour
```

**Not yet charging (added in next steps):**

- Worker nodes: $0/hour (not created yet)
- Storage: $0/hour (no volumes yet)

**How to monitor costs:**

```bash
# Check EKS costs via CLI
aws ce get-cost-and-usage \
    --time-period Start=2024-12-01,End=2024-12-04 \
    --granularity DAILY \
    --metrics UnblendedCost \
    --filter file://eks-cost-filter.json

# Create filter file:
cat > eks-cost-filter.json << EOF
{
  "Dimensions": {
    "Key": "SERVICE",
    "Values": ["Amazon Elastic Kubernetes Service"]
  }
}
EOF
```

---

## 🎓 What You've Accomplished

```
✅ Created EKS control plane
✅ Kubernetes API server running
✅ Multi-AZ highly available setup
✅ Cluster accessible via kubectl
✅ Ready for worker nodes
✅ Ready for participants

Control Plane Components (AWS Managed):
├── API Server (port 443)
├── Scheduler
├── Controller Manager
└── etcd Database (3 replicas across 3 AZs)

Your cluster can now:
├── Accept kubectl commands
├── Manage Kubernetes resources
├── Schedule pods (once nodes are added)
└── Serve all 7 participants
```

---

## 🚀 Next Steps

Cluster created successfully! Continue to:

**Next:** [04-INITIAL-NODE-GROUP.md](04-INITIAL-NODE-GROUP.md) - Add worker nodes

The cluster is running but has no capacity to run pods yet. You need worker nodes!

---

## 📚 Additional Resources

- [Amazon EKS Clusters](https://docs.aws.amazon.com/eks/latest/userguide/clusters.html)
- [Cluster Endpoint Access Control](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html)
- [EKS Control Plane Logging](https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)
- [kubectl Configuration](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
