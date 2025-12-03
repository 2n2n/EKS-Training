# Cleanup Guide - For Root Account

**For:** Workshop Administrator (Root Account Only)  
**Time:** 30-45 minutes  
**When:** After workshop completion

This guide walks you through deleting all workshop resources to stop AWS charges.

---

## ⚠️ Important Warnings

**THIS IS DESTRUCTIVE AND IRREVERSIBLE!**

- All participant work will be deleted
- All data will be lost
- Cannot be undone

**Before Starting:**
- [ ] Confirm workshop is completely finished
- [ ] All participants have saved any work they want to keep
- [ ] All participants have been notified of deletion
- [ ] You have 30-45 minutes available

---

## 📋 Cleanup Order

**Critical:** Delete resources in this order to avoid dependency errors:

1. Participant workloads (namespaces)
2. Node groups
3. EKS cluster
4. ECR repository and images
5. VPC resources (subnets, IGW, security groups, VPC)
6. IAM roles (cluster and node roles)

---

## Step 1: Delete Participant Namespaces (5 min)

First, delete all participant-created resources.

### Via kubectl

```bash
# List all namespaces
kubectl get namespaces

# Delete participant namespaces (one by one or all at once)
kubectl delete namespace charles-workspace
kubectl delete namespace joshua-workspace
kubectl delete namespace robert-workspace
kubectl delete namespace sharmaine-workspace
kubectl delete namespace daniel-workspace
kubectl delete namespace jett-workspace
kubectl delete namespace thon-workspace

# Or delete all non-system namespaces at once:
kubectl get namespaces --no-headers | grep -v 'default\|kube-' | awk '{print $1}' | xargs kubectl delete namespace
```

**What this does:**
- Deletes all deployments, pods, services in those namespaces
- Releases all resources used by participants
- May take 1-2 minutes per namespace

**Wait for completion:**
```bash
# Verify namespaces are gone
kubectl get namespaces
# Should only see: default, kube-system, kube-public, kube-node-lease
```

---

## Step 2: Delete Node Groups (10-15 min)

### Via AWS Console

1. Go to **EKS Console**
2. Click on **shared-workshop-cluster**
3. Go to **Compute** tab
4. For each node group:
   - Select the node group
   - Click **Delete**
   - Type the node group name to confirm
   - Click **Delete**
5. **Wait for deletion to complete** (~10 minutes per node group)

### Via AWS CLI

```bash
# List all node groups
aws eks list-nodegroups \
    --cluster-name shared-workshop-cluster \
    --region ap-southeast-1

# Delete each node group
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \
    --region ap-southeast-1

# If participants created additional node groups, delete those too
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <participant-nodegroup-name> \
    --region ap-southeast-1

# Wait for deletion (check status)
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \
    --region ap-southeast-1 \
    --query 'nodegroup.status'
```

**Monitor deletion:**
```bash
# Should transition: DELETING → (deleted/not found)
# Takes ~10 minutes per node group
```

**What this does:**
- Terminates all EC2 instances
- Deletes auto-scaling groups
- Releases EBS volumes
- Stops compute charges

---

## Step 3: Delete EKS Cluster (15-20 min)

**Wait for Step 2 to complete!** All node groups must be deleted first.

### Via AWS Console

1. Go to **EKS Console**
2. Select **shared-workshop-cluster**
3. Click **Delete cluster**
4. Type the cluster name: `shared-workshop-cluster`
5. Click **Delete**
6. **Wait for deletion** (~15 minutes)

### Via AWS CLI

```bash
# Delete the cluster
aws eks delete-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1

# Monitor deletion
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.status'

# Wait for completion
aws eks wait cluster-deleted \
    --name shared-workshop-cluster \
    --region ap-southeast-1
```

**What this does:**
- Deletes EKS control plane
- Removes CloudFormation stacks
- Deletes elastic network interfaces (ENIs)
- Stops $72/month control plane charge

**Monitor progress:**
```bash
# Cluster status should be: DELETING → (not found)
# Takes ~15 minutes
```

---

## Step 4: Delete ECR Repository (2 min)

### Via AWS Console

1. Go to **ECR Console**
2. Select **eks-workshop-apps** repository
3. Click **Delete**
4. Type `delete` to confirm
5. Click **Delete**

### Via AWS CLI

```bash
# Delete repository (force deletes all images)
aws ecr delete-repository \
    --repository-name eks-workshop-apps \
    --force \
    --region ap-southeast-1
```

**What this does:**
- Deletes all Docker images
- Removes repository
- Stops ECR storage charges

---

## Step 5: Delete VPC Resources (5-10 min)

**Wait for Step 3 to complete!** Cluster must be fully deleted first to release ENIs.

### Important Note About ENIs

EKS creates Elastic Network Interfaces (ENIs) that may take extra time to delete after cluster deletion. If VPC deletion fails due to ENIs:

```bash
# Check for leftover ENIs
aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

# Wait 5-10 minutes, then try VPC deletion again
```

---

### Delete Security Groups

**Via AWS Console:**

1. Go to **VPC Console** → **Security Groups**
2. Select **eks-workshop-node-sg**
3. Click **Actions** → **Delete security groups**
4. Confirm deletion
5. Select **eks-workshop-cluster-sg**
6. Click **Actions** → **Delete security groups**
7. Confirm deletion

**Via AWS CLI:**
```bash
# Get security group IDs
aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --query 'SecurityGroups[?GroupName!=`default`].[GroupId,GroupName]' \
    --region ap-southeast-1

# Delete node security group
aws ec2 delete-security-group \
    --group-id <node-sg-id> \
    --region ap-southeast-1

# Delete cluster security group
aws ec2 delete-security-group \
    --group-id <cluster-sg-id> \
    --region ap-southeast-1
```

---

### Detach and Delete Internet Gateway

**Via AWS Console:**

1. Go to **VPC Console** → **Internet Gateways**
2. Select **eks-workshop-igw**
3. Click **Actions** → **Detach from VPC**
4. Select the VPC and click **Detach internet gateway**
5. Select **eks-workshop-igw** again
6. Click **Actions** → **Delete internet gateway**
7. Confirm deletion

**Via AWS CLI:**
```bash
# Get IGW ID
IGW_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=<vpc-id>" \
    --query 'InternetGateways[0].InternetGatewayId' \
    --output text \
    --region ap-southeast-1)

# Detach from VPC
aws ec2 detach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id <vpc-id> \
    --region ap-southeast-1

# Delete IGW
aws ec2 delete-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --region ap-southeast-1
```

---

### Delete Subnets

**Via AWS Console:**

1. Go to **VPC Console** → **Subnets**
2. Select **eks-workshop-public-a**
3. Click **Actions** → **Delete subnet**
4. Confirm
5. Select **eks-workshop-public-b**
6. Click **Actions** → **Delete subnet**
7. Confirm

**Via AWS CLI:**
```bash
# Get subnet IDs
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --query 'Subnets[].[SubnetId,Tags[?Key==`Name`].Value|[0]]' \
    --region ap-southeast-1

# Delete subnets
aws ec2 delete-subnet \
    --subnet-id <subnet-a-id> \
    --region ap-southeast-1

aws ec2 delete-subnet \
    --subnet-id <subnet-b-id> \
    --region ap-southeast-1
```

---

### Delete VPC

**Via AWS Console:**

1. Go to **VPC Console** → **Your VPCs**
2. Select **eks-workshop-vpc**
3. Click **Actions** → **Delete VPC**
4. Type `delete` to confirm
5. Click **Delete**

**Via AWS CLI:**
```bash
# Delete VPC
aws ec2 delete-vpc \
    --vpc-id <vpc-id> \
    --region ap-southeast-1
```

---

## Step 6: Delete IAM Roles (3 min)

### Via AWS Console

**Delete Node Role:**
1. Go to **IAM Console** → **Roles**
2. Search for `eks-workshop-node-role`
3. Select the role
4. Click **Delete**
5. Type the role name to confirm
6. Click **Delete**

**Delete Cluster Role:**
1. Search for `eks-workshop-cluster-role`
2. Select the role
3. Click **Delete**
4. Type the role name to confirm
5. Click **Delete**

### Via AWS CLI

```bash
# Delete node role
# First detach policies
aws iam detach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam detach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam detach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Delete instance profile if exists
aws iam remove-role-from-instance-profile \
    --instance-profile-name eks-workshop-node-role \
    --role-name eks-workshop-node-role 2>/dev/null || true

aws iam delete-instance-profile \
    --instance-profile-name eks-workshop-node-role 2>/dev/null || true

# Delete role
aws iam delete-role \
    --role-name eks-workshop-node-role

# Delete cluster role
aws iam detach-role-policy \
    --role-name eks-workshop-cluster-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam delete-role \
    --role-name eks-workshop-cluster-role
```

---

## ✅ Verification

Verify all resources are deleted to ensure no ongoing charges.

### Check EKS

```bash
# Should return empty list
aws eks list-clusters --region ap-southeast-1

# Expected output:
# {
#     "clusters": []
# }
```

### Check EC2 Instances

```bash
# Should return no running instances (or only unrelated ones)
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --region ap-southeast-1 \
    --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0]]'
```

### Check VPCs

```bash
# Should only show default VPC
aws ec2 describe-vpcs --region ap-southeast-1 \
    --query 'Vpcs[?CidrBlock==`10.0.0.0/16`]'

# Expected output:
# []
```

### Check ECR

```bash
# Should not find eks-workshop-apps
aws ecr describe-repositories --region ap-southeast-1 \
    --query 'repositories[?repositoryName==`eks-workshop-apps`]'

# Expected output:
# []
```

### Check IAM Roles

```bash
# Should return empty
aws iam list-roles \
    --query 'Roles[?contains(RoleName, `eks-workshop`)]'

# Expected output:
# []
```

### Check EBS Volumes

```bash
# Should show no available (unattached) volumes
aws ec2 describe-volumes \
    --filters "Name=status,Values=available" \
    --region ap-southeast-1
```

---

## 💰 Verify No Ongoing Charges

### Check AWS Billing

1. Go to **AWS Console** → **Billing** → **Bills**
2. Look at current month charges
3. Check these services show $0 or minimal:
   - **Amazon Elastic Kubernetes Service:** $0
   - **Amazon EC2:** $0 (or only unrelated resources)
   - **Amazon EC2 Container Registry:** $0
   - **Amazon Virtual Private Cloud:** $0

### Set Up Billing Alert (If Not Already Done)

1. Go to **Billing** → **Billing preferences**
2. Enable **Receive Billing Alerts**
3. Save preferences
4. Go to **CloudWatch** → **Alarms** → **Billing**
5. Create alarm for >$5 or >$10

---

## 🚨 Troubleshooting

### Issue: Can't Delete Security Group

**Error:** "has a dependent object" or "is being used"

**Solution:**
```bash
# Wait 5-10 minutes for ENIs to be deleted
# Check for leftover ENIs
aws ec2 describe-network-interfaces \
    --filters "Name=group-id,Values=<security-group-id>" \
    --region ap-southeast-1

# If ENIs still exist, delete them manually:
aws ec2 delete-network-interface \
    --network-interface-id <eni-id> \
    --region ap-southeast-1
```

---

### Issue: Can't Delete VPC

**Error:** "has dependencies"

**Possible remaining resources:**
- Security groups
- Network interfaces (ENIs)
- Route tables
- Subnets

**Solution:**
```bash
# Check what's left
aws ec2 describe-vpcs --vpc-ids <vpc-id> --region ap-southeast-1

# List all resources in VPC
aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

# Delete them one by one, then retry VPC deletion
```

---

### Issue: Cluster Stuck in Deleting

**If stuck for >30 minutes:**

1. Check CloudFormation stacks:
   ```bash
   aws cloudformation list-stacks \
       --stack-status-filter DELETE_IN_PROGRESS DELETE_FAILED \
       --region ap-southeast-1
   ```

2. Check for stuck resources in CloudFormation events
3. May need to contact AWS Support if truly stuck

---

### Issue: IAM Role Can't Be Deleted

**Error:** "Cannot delete entity, must detach all policies first"

**Solution:**
```bash
# List all attached policies
aws iam list-attached-role-policies \
    --role-name eks-workshop-node-role

# Detach each one
aws iam detach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn <policy-arn>

# Then delete role
aws iam delete-role --role-name eks-workshop-node-role
```

---

## 📋 Cleanup Checklist

Use this to track your progress:

- [ ] **Step 1:** Deleted all participant namespaces
- [ ] **Step 2:** Deleted all node groups (waited for completion)
- [ ] **Step 3:** Deleted EKS cluster (waited for completion)
- [ ] **Step 4:** Deleted ECR repository
- [ ] **Step 5:** Deleted VPC resources:
  - [ ] Security groups deleted
  - [ ] Internet Gateway detached and deleted
  - [ ] Subnets deleted
  - [ ] VPC deleted
- [ ] **Step 6:** Deleted IAM roles
- [ ] **Verification:** All checks passed
- [ ] **Billing:** Confirmed no ongoing charges

---

## 📊 Final Cost Summary

After complete cleanup:

```
Ongoing Costs:
├── EKS Control Plane: $0 (deleted)
├── EC2 Instances: $0 (terminated)
├── EBS Volumes: $0 (deleted)
├── ECR Storage: $0 (deleted)
├── VPC: $0 (free anyway)
└── Total: $0/month

Workshop Total Cost (4 hours):
└── ~$0.52 shared by all 7 participants
```

---

## 🎓 Post-Workshop

### What to Keep

**DO NOT DELETE these (if you want to run workshop again):**
- IAM users (eks-charles, eks-joshua, etc.)
- IAM group (EKSWorkshopParticipants)
- IAM policy (EKSWorkshopPolicy)

These can be reused for future workshops!

### What Was Deleted

- ✅ EKS cluster
- ✅ Worker nodes
- ✅ VPC and networking
- ✅ ECR repository
- ✅ IAM roles (cluster and node - can recreate)
- ✅ All participant workloads

### To Run Workshop Again

1. Keep IAM users, group, policy
2. Follow ROOT-SETUP guides again (1-2 hours)
3. Participants can use same credentials
4. Fresh cluster for new session

---

## ✅ Cleanup Complete!

If all verification checks passed:
- 🎉 All workshop resources deleted
- 💰 No ongoing AWS charges
- 📚 Participants learned EKS and Kubernetes
- 🤝 Successful collaborative workshop!

**Total cleanup time:** ~30-45 minutes

---

**Thank you for running this workshop! Your participants learned valuable cloud-native skills in a cost-effective shared environment.**

