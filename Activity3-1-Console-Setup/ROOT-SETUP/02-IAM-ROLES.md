# Root Setup 02: IAM Roles

**For:** Workshop Administrator (Root Account)  
**Time:** 20 minutes  
**Cost Impact:** $0 (IAM is free)

Create the IAM roles needed for EKS cluster and worker nodes to function properly.

---

## 🎯 What You'll Create

- 1× EKS Cluster Service Role (for control plane)
- 1× EKS Node Instance Role (for worker nodes)
- Required AWS managed policies attached to each

---

## 📋 Prerequisites

- [ ] Completed [01-VPC-AND-NETWORKING.md](01-VPC-AND-NETWORKING.md)
- [ ] IAM permissions: `iam:CreateRole`, `iam:AttachRolePolicy`
- [ ] Region: **ap-southeast-1**

---

## Understanding IAM Roles

**What are IAM Roles?**

- Identity that AWS services can assume
- Like a "service account" in traditional IT
- Grants permissions without access keys
- More secure than hardcoded credentials

**Why Two Roles?**

- **Cluster Role:** Used by EKS control plane to manage AWS resources
- **Node Role:** Used by worker nodes to join cluster and access services

---

## Step 1: Create EKS Cluster Service Role (10 min)

This role allows the EKS control plane to manage AWS resources on your behalf.

### Via AWS Console

1. Go to **IAM Console**: https://console.aws.amazon.com/iam/
2. Click **Roles** in left sidebar
3. Click **Create role**

**Step 1: Select trusted entity**

```
Trusted entity type: AWS service
Use case: EKS → EKS - Cluster
```

4. Click **Next**

**Step 2: Add permissions**

- The policy `AmazonEKSClusterPolicy` should be automatically selected
- This is correct - don't add or remove anything

5. Click **Next**

**Step 3: Name and review**

```
Role name: eks-workshop-cluster-role
Description: Allows EKS to manage AWS resources for the workshop cluster
```

6. Click **Create role**

### Via AWS CLI

```bash
# Create trust policy document
cat > eks-cluster-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name eks-workshop-cluster-role \
    --assume-role-policy-document file://eks-cluster-trust-policy.json \
    --description "Allows EKS to manage AWS resources for the workshop cluster"

# Attach the required policy
aws iam attach-role-policy \
    --role-name eks-workshop-cluster-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Verify
aws iam get-role --role-name eks-workshop-cluster-role
```

### What This Role Does

**AmazonEKSClusterPolicy allows EKS to:**

- Create and manage elastic network interfaces (ENIs)
- Manage security groups for cluster communication
- Create and manage load balancers for services
- Access EC2 resources needed for cluster operation

**Without this role:**

- EKS cluster cannot be created
- Control plane cannot manage AWS resources
- Cluster would be non-functional

---

## Step 2: Create EKS Node Instance Role (10 min)

This role allows worker nodes to:

- Join the EKS cluster
- Pull container images from ECR
- Manage pod networking (CNI)

### Via AWS Console

1. In IAM Console, click **Roles** → **Create role**

**Step 1: Select trusted entity**

```
Trusted entity type: AWS service
Use case: EC2
```

2. Click **Next**

**Step 2: Add permissions**

Search for and select these 3 policies:

- ☑ `AmazonEKSWorkerNodePolicy`
- ☑ `AmazonEKS_CNI_Policy`
- ☑ `AmazonEC2ContainerRegistryReadOnly`

3. Click **Next**

**Step 3: Name and review**

```
Role name: eks-workshop-node-role
Description: Allows EC2 instances to join EKS cluster and access required services
```

4. Click **Create role**

### Via AWS CLI

```bash
# Create trust policy for EC2
cat > eks-node-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name eks-workshop-node-role \
    --assume-role-policy-document file://eks-node-trust-policy.json \
    --description "Allows EC2 instances to join EKS cluster"

# Attach required policies
aws iam attach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
    --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Verify
aws iam get-role --role-name eks-workshop-node-role
aws iam list-attached-role-policies --role-name eks-workshop-node-role
```

### What Each Policy Does

**AmazonEKSWorkerNodePolicy:**

```
Allows nodes to:
├── Connect to EKS cluster
├── Send logs and metrics
├── Describe cluster resources
└── Communicate with control plane
```

**AmazonEKS_CNI_Policy:**

```
Allows CNI plugin to:
├── Assign IP addresses to pods
├── Manage network interfaces (ENIs)
├── Configure pod networking
└── Enable pod-to-pod communication
```

**AmazonEC2ContainerRegistryReadOnly:**

```
Allows nodes to:
├── Pull images from ECR
├── Authenticate with ECR
├── Download container layers
└── Access public ECR repositories
```

**Without these policies:**

- Nodes cannot join cluster
- Pods cannot get IP addresses
- Cannot pull container images
- Cluster is non-functional

---

## ✅ Validation

Verify both roles are created correctly.

### Via AWS Console

1. Go to **IAM Console** → **Roles**
2. Search for "eks-workshop"
3. You should see:
   - **eks-workshop-cluster-role**
   - **eks-workshop-node-role**

**Check Cluster Role:**

1. Click **eks-workshop-cluster-role**
2. **Permissions** tab should show:
   - Policy: `AmazonEKSClusterPolicy`
3. **Trust relationships** tab should show:
   - Trusted entity: `eks.amazonaws.com`

**Check Node Role:**

1. Click **eks-workshop-node-role**
2. **Permissions** tab should show 3 policies:
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonEC2ContainerRegistryReadOnly`
3. **Trust relationships** tab should show:
   - Trusted entity: `ec2.amazonaws.com`

### Via AWS CLI

```bash
# List both roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eks-workshop`)].RoleName'

# Expected output:
# [
#     "eks-workshop-cluster-role",
#     "eks-workshop-node-role"
# ]

# Check cluster role policies
aws iam list-attached-role-policies \
    --role-name eks-workshop-cluster-role \
    --query 'AttachedPolicies[].PolicyName'

# Expected: ["AmazonEKSClusterPolicy"]

# Check node role policies
aws iam list-attached-role-policies \
    --role-name eks-workshop-node-role \
    --query 'AttachedPolicies[].PolicyName'

# Expected:
# [
#     "AmazonEKSWorkerNodePolicy",
#     "AmazonEKS_CNI_Policy",
#     "AmazonEC2ContainerRegistryReadOnly"
# ]

# Get role ARNs (save these for next steps)
aws iam get-role \
    --role-name eks-workshop-cluster-role \
    --query 'Role.Arn' \
    --output text

aws iam get-role \
    --role-name eks-workshop-node-role \
    --query 'Role.Arn' \
    --output text
```

### Checklist

- [ ] Cluster role created
- [ ] Cluster role has AmazonEKSClusterPolicy attached
- [ ] Cluster role trusts eks.amazonaws.com
- [ ] Node role created
- [ ] Node role has all 3 required policies attached
- [ ] Node role trusts ec2.amazonaws.com

---

## 📝 Save These Values

You'll need the role ARNs in the next step. Save them:

```bash
# Get and save ARNs
echo "Cluster Role ARN:"
aws iam get-role --role-name eks-workshop-cluster-role --query 'Role.Arn' --output text

echo "Node Role ARN:"
aws iam get-role --role-name eks-workshop-node-role --query 'Role.Arn' --output text
```

Save to a file:

```
Cluster Role ARN: arn:aws:iam::<account-id>:role/eks-workshop-cluster-role
Node Role ARN: arn:aws:iam::<account-id>:role/eks-workshop-node-role
```

---

## 🚨 Troubleshooting

### Issue: Can't Find EKS Use Case

**In Console, don't see "EKS" under use cases?**

**Solution:**

- Make sure you selected "AWS service" as trusted entity type
- Scroll down in the use case list
- It's under "EKS" section
- Or search for "eks" in the filter box

---

### Issue: Policy Not Attaching

**Error:** "User is not authorized to perform: iam:AttachRolePolicy"

**Solution:**

- You need IAM permissions to create roles and attach policies
- Contact your AWS administrator
- Or use root account (not recommended for production)

---

### Issue: Wrong Trust Policy

**Error when using role:** "AssumeRole not authorized"

**Solution:**

```bash
# Check trust policy
aws iam get-role --role-name eks-workshop-cluster-role \
    --query 'Role.AssumeRolePolicyDocument'

# Should show eks.amazonaws.com for cluster role
# Should show ec2.amazonaws.com for node role

# If wrong, delete and recreate role
```

---

## 💡 Understanding Trust Policies

**Trust Policy vs Permission Policy:**

```
Trust Policy (Who can use this role):
├── eks.amazonaws.com can assume cluster role
└── ec2.amazonaws.com can assume node role

Permission Policy (What the role can do):
├── AmazonEKSClusterPolicy defines cluster permissions
├── AmazonEKSWorkerNodePolicy defines node permissions
├── AmazonEKS_CNI_Policy defines networking permissions
└── AmazonEC2ContainerRegistryReadOnly defines image pull permissions
```

**Analogy:**

- Trust Policy = Who can enter the building
- Permission Policy = What rooms they can access once inside

---

## 🔐 Security Best Practices

### Principle of Least Privilege

These roles have only the minimum permissions needed:

**Cluster Role:**

- ✅ Can manage cluster networking and load balancers
- ❌ Cannot access S3, databases, or other services
- ❌ Cannot manage IAM or billing

**Node Role:**

- ✅ Can join cluster and pull images
- ❌ Cannot create/delete AWS resources
- ❌ Cannot access other services unnecessarily

### Role Naming

Good naming helps identify purpose:

```
✅ eks-workshop-cluster-role (clear purpose)
❌ my-role-1 (unclear)
❌ admin-role (too broad)
```

### Audit Trail

All role usage is logged in CloudTrail:

```bash
# View recent role usage
aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey=ResourceName,AttributeValue=eks-workshop-cluster-role \
    --max-results 10
```

---

## 📚 Additional Information

### AWS Managed Policies

These policies are maintained by AWS:

- AWS updates them as EKS evolves
- You get new features automatically
- No need to manually update permissions

### Custom Policies (Not Needed for Workshop)

For production, you might create custom policies to:

- Add encryption permissions for encrypted volumes
- Add CloudWatch logging permissions
- Add additional security requirements

---

## 🚀 Next Steps

IAM roles created! Continue to:

**Next:** [03-EKS-CLUSTER-CREATION.md](03-EKS-CLUSTER-CREATION.md) - Create the EKS cluster

**Important:** After cluster creation, you'll need to grant participant access. Modern EKS clusters use **Access Entries** instead of ConfigMap. See:

- [06-EKS-ACCESS-ENTRIES-TROUBLESHOOTING.md](06-EKS-ACCESS-ENTRIES-TROUBLESHOOTING.md) - For API authentication mode
- [05-PARTICIPANT-ACCESS.md](05-PARTICIPANT-ACCESS.md) - For ConfigMap authentication mode (legacy)

---

## Quick Command Reference

```bash
# List IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`)].RoleName'

# Get role details
aws iam get-role --role-name eks-workshop-cluster-role

# List attached policies
aws iam list-attached-role-policies --role-name eks-workshop-node-role

# Get policy details
aws iam get-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Detach policy (if needed for cleanup)
aws iam detach-role-policy \
    --role-name eks-workshop-cluster-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Delete role (cleanup only - not now!)
aws iam delete-role --role-name eks-workshop-cluster-role
```

---

## 📖 Additional Resources

- [IAM Roles Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [EKS Cluster IAM Role](https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html)
- [EKS Node IAM Role](https://docs.aws.amazon.com/eks/latest/userguide/create-node-role.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
