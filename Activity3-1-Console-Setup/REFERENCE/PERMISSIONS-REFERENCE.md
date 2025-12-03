# Permissions Reference

Understanding IAM and Kubernetes RBAC permissions in this workshop.

---

## 📋 Table of Contents

- [Overview: IAM vs RBAC](#overview-iam-vs-rbac)
- [Root Account Permissions](#root-account-permissions)
- [Participant Permissions](#participant-permissions)
- [IAM Roles](#iam-roles)
- [Kubernetes RBAC](#kubernetes-rbac)
- [Security Best Practices](#security-best-practices)

---

## Overview: IAM vs RBAC

### Two Permission Systems

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            IAM (Identity & Access Management)        │   │
│  │  - Controls access to AWS services                   │   │
│  │  - Who can create/delete EKS clusters               │   │
│  │  - Who can push to ECR                              │   │
│  │  - Who can manage EC2 instances                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              EKS Cluster                             │   │
│  │  ┌───────────────────────────────────────────────┐  │   │
│  │  │        RBAC (Role-Based Access Control)       │  │   │
│  │  │  - Controls access INSIDE the cluster         │  │   │
│  │  │  - Who can create pods                        │  │   │
│  │  │  - Who can view secrets                       │  │   │
│  │  │  - Who can delete deployments                 │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### How They Connect (aws-auth ConfigMap)

```yaml
# AWS IAM User → Kubernetes RBAC mapping
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::123456789012:user/eks-charles
      username: charles
      groups:
        - system:masters   # ← Kubernetes RBAC group
```

---

## Root Account Permissions

### Required for Setup

The root/admin account needs:

```
AWS Permissions:
├── EC2: Full access (VPC, subnets, security groups)
├── EKS: Full access (create cluster, node groups)
├── IAM: Create/manage roles and policies
├── ECR: Create repositories, manage policies
└── CloudFormation: Optional (if using IaC)
```

### Typical Admin Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:*",
        "ec2:*",
        "ecr:*",
        "iam:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Participant Permissions

### IAM Permissions (AWS Level)

Participants in this workshop have:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EKSFullAccess",
      "Effect": "Allow",
      "Action": "eks:*",
      "Resource": "*"
    },
    {
      "Sid": "EC2FullAccess",
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Sid": "ECRFullAccess",
      "Effect": "Allow",
      "Action": "ecr:*",
      "Resource": "*"
    },
    {
      "Sid": "LimitedIAM",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRoles",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### What Participants CAN Do (AWS)

✅ List and describe EKS clusters
✅ Create and delete node groups
✅ Push/pull images to ECR
✅ Update kubeconfig
✅ View VPC and networking
✅ Describe EC2 instances (nodes)

### What Participants CANNOT Do (AWS)

❌ Create new EKS clusters
❌ Delete the shared EKS cluster
❌ Create IAM roles
❌ Modify IAM policies
❌ Delete the VPC

### Kubernetes Permissions (Cluster Level)

With `system:masters` group:

```
Kubernetes Access:
├── Namespaces: Create, delete, list all
├── Pods: Full CRUD in any namespace
├── Deployments: Full CRUD in any namespace
├── Services: Full CRUD in any namespace
├── Secrets: Full access (read, create, delete)
├── ConfigMaps: Full access
├── Nodes: View, label, taint, cordon
└── Everything else: Full admin access
```

### What Participants CAN Do (Kubernetes)

✅ Create/delete namespaces
✅ Deploy any application
✅ View all pods, deployments, services
✅ View secrets and configmaps
✅ Label and taint nodes
✅ Scale deployments
✅ View logs from any pod

### What Participants SHOULD NOT Do

❌ Delete `kube-system` namespace
❌ Modify system pods
❌ Delete others' resources
❌ Use excessive cluster resources
❌ Delete shared node groups

---

## IAM Roles

### EKS Cluster Service Role

**Purpose:** Allows EKS service to manage cluster resources

```json
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
```

**Attached Policies:**
- `AmazonEKSClusterPolicy`

### EKS Node Instance Role

**Purpose:** Allows EC2 instances (nodes) to join cluster and pull images

```json
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
```

**Attached Policies:**
- `AmazonEKSWorkerNodePolicy` - Node registration
- `AmazonEC2ContainerRegistryReadOnly` - Pull images from ECR
- `AmazonEKS_CNI_Policy` - Pod networking

---

## Kubernetes RBAC

### Built-in Cluster Roles

```bash
# View cluster roles
kubectl get clusterroles

# Common roles:
# cluster-admin - Full access to everything
# admin - Full access within namespace
# edit - Read/write most resources
# view - Read-only access
```

### system:masters Group

The most privileged group in Kubernetes:

```yaml
# Participants are mapped to this group
groups:
  - system:masters
```

**Grants:**
- Equivalent to `cluster-admin` ClusterRole
- Full access to all resources in all namespaces
- Cannot be restricted by RBAC

### Safer Alternative: Custom RBAC

For production, create limited roles:

```yaml
# participant-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: workshop-participant
rules:
# Namespaces - can create and manage own
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list", "create", "delete"]

# Full access to workloads
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "services", "jobs", "configmaps"]
  verbs: ["*"]

# Read-only nodes
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]

# No access to secrets (safer)
# No access to kube-system namespace
```

### Viewing Your Permissions

```bash
# Check what you can do
kubectl auth can-i create pods
kubectl auth can-i delete namespaces
kubectl auth can-i create secrets

# Check for specific namespace
kubectl auth can-i create pods -n kube-system

# Check as another user
kubectl auth can-i create pods --as charles
```

---

## Security Best Practices

### For Shared Workshop Environment

1. **Use Personal Namespaces**
   ```bash
   # Always work in YOUR namespace
   kubectl config set-context --current --namespace=charles-workspace
   ```

2. **Name Resources Clearly**
   ```bash
   # Include your name
   charles-webapp
   charles-api
   charles-nodes
   ```

3. **Don't Touch System Resources**
   ```bash
   # Never modify these namespaces:
   kube-system
   kube-public
   kube-node-lease
   ```

4. **Be Careful with Cluster-Wide Resources**
   ```bash
   # These affect everyone:
   kubectl taint nodes ...      # ⚠️ Affects pod scheduling
   kubectl label nodes ...      # ⚠️ Can affect node selectors
   kubectl delete namespace ... # ⚠️ Could delete others' work
   ```

### Production Recommendations

For real production environments:

1. **Don't use system:masters**
   - Create custom RBAC roles
   - Limit to specific namespaces
   - Restrict secret access

2. **Use IAM Roles for Service Accounts (IRSA)**
   - Pods get specific AWS permissions
   - No shared credentials

3. **Enable Audit Logging**
   - Track who did what
   - CloudTrail for AWS
   - Kubernetes audit logs

4. **Network Policies**
   - Restrict pod-to-pod communication
   - Isolate namespaces

---

## 🔍 Audit: Who Did What?

### AWS CloudTrail

View AWS API calls:

```bash
# Via AWS Console
CloudTrail → Event history

# Filter by:
# - User name
# - Event name (CreateNodegroup, etc.)
# - Resource type
```

### Kubernetes Events

View cluster events:

```bash
# Recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Events for specific resource
kubectl describe pod <name> | grep Events -A 20
```

---

## 📝 Permission Troubleshooting

### "You must be logged in to the server (Unauthorized)"

```bash
# Check AWS identity
aws sts get-caller-identity

# Verify user is in aws-auth
kubectl get configmap aws-auth -n kube-system -o yaml

# Re-run kubeconfig setup
aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1
```

### "forbidden: User cannot..."

```bash
# Check what you can do
kubectl auth can-i <verb> <resource>

# Example
kubectl auth can-i create pods -n kube-system

# If no, check:
# 1. Are you in aws-auth ConfigMap?
# 2. What groups are you mapped to?
# 3. What RBAC roles exist?
```

### "AccessDenied" (AWS)

```bash
# Check IAM policies
aws iam list-attached-user-policies --user-name <your-user>

# Check specific permission
aws iam simulate-principal-policy \
    --policy-source-arn arn:aws:iam::xxx:user/<your-user> \
    --action-names eks:CreateNodegroup
```

---

## 🔗 Additional Resources

- [EKS Authentication](https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [AWS IAM Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html)
- [EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/)

