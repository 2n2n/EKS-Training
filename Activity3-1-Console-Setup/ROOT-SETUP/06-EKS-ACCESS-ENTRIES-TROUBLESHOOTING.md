# EKS Access Entries - Troubleshooting Guide

**For:** Workshop Administrator & Participants  
**Time:** 10 minutes to fix  
**Issue:** "Your current IAM principal doesn't have access to Kubernetes objects"

This guide explains why participants may encounter access issues even with proper IAM permissions, and how to resolve them using EKS Access Entries.

---

## 🎯 The Problem

A participant runs:

```bash
aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1
```

Then tries:

```bash
kubectl get nodes
```

**Error received:**

```
error: You must be logged in to the server (Unauthorized)

Your current IAM principal doesn't have access to Kubernetes objects on this cluster.
This might be due to the current principal not having an IAM access entry with
permissions to access the cluster.
```

**Why does this happen?**  
The IAM user has AWS-level permissions but lacks Kubernetes-level access configuration.

---

## 📚 Understanding EKS Authentication

### Two Authentication Methods

EKS clusters use one of three authentication modes:

| Mode                   | Description              | How Access is Granted                            |
| ---------------------- | ------------------------ | ------------------------------------------------ |
| **CONFIG_MAP**         | Legacy method (pre-2023) | Edit aws-auth ConfigMap in kube-system namespace |
| **API**                | Modern method (2023+)    | Create EKS Access Entries via AWS API            |
| **API_AND_CONFIG_MAP** | Hybrid                   | Both methods work simultaneously                 |

**Your cluster is likely using `API` mode**, which requires EKS Access Entries instead of ConfigMap edits.

### Check Your Cluster's Authentication Mode

```bash
# Check what authentication mode your cluster uses
aws eks describe-cluster \
    --name <cluster-name> \
    --region <region> \
    --query 'cluster.accessConfig.authenticationMode' \
    --output text

# Possible outputs:
# - CONFIG_MAP (use aws-auth ConfigMap - see 05-PARTICIPANT-ACCESS.md)
# - API (use Access Entries - THIS GUIDE!)
# - API_AND_CONFIG_MAP (both methods work)
```

---

## 🔍 Understanding the Two Permission Layers

Even with proper IAM permissions, you need BOTH layers configured:

```
┌─────────────────────────────────────────────────────┐
│  Layer 1: AWS IAM Permissions                       │
│  Question: Can this user call AWS EKS APIs?         │
│  ✅ Already granted via EKSWorkshopPolicy           │
└─────────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────┐
│  Layer 2: EKS Access Entry + Policy                 │
│  Question: What can user do INSIDE the cluster?     │
│  ❌ THIS IS THE MISSING PIECE!                      │
└─────────────────────────────────────────────────────┘
```

**Analogy:**

- **IAM Permission** = Can you enter the building? ✅
- **Access Entry** = Is your name on the guest list? ❌
- **Access Policy** = Which rooms can you access once inside? ❌

---

## 🛠️ Solution: Create Access Entries

### Step 1: Check Current Access Entries

**For Administrator - Check who has access:**

```bash
# List all access entries for the cluster
aws eks list-access-entries \
    --cluster-name <cluster-name> \
    --region <region> \
    --output json

# Example output:
# {
#     "accessEntries": [
#         "arn:aws:iam::123456789012:user/eks-robert",
#         "arn:aws:iam::123456789012:user/eks-charles"
#     ]
# }
```

**Check specific user:**

```bash
# Replace with actual user ARN
USER_ARN="arn:aws:iam::123456789012:user/eks-robert"
CLUSTER_NAME="shared-workshop-cluster"
REGION="ap-southeast-1"

# Check if access entry exists
aws eks describe-access-entry \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --output json
```

**Check associated policies:**

```bash
# Check what policies are attached
aws eks list-associated-access-policies \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --output json

# If this returns empty "associatedAccessPolicies": []
# Then the user has NO access policies = NO Kubernetes permissions!
```

---

### Step 2: Create Access Entry (If Missing)

If the user doesn't have an access entry, create one:

```bash
# Variables - REPLACE THESE!
CLUSTER_NAME="shared-workshop-cluster"
REGION="ap-southeast-1"
USER_ARN="arn:aws:iam::123456789012:user/eks-<username>"

# Create access entry
aws eks create-access-entry \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN"

# Output:
# {
#     "accessEntry": {
#         "clusterName": "shared-workshop-cluster",
#         "principalArn": "arn:aws:iam::123456789012:user/eks-username",
#         "kubernetesGroups": [],
#         "accessEntryArn": "...",
#         "createdAt": "2024-12-04T12:00:00+00:00",
#         "type": "STANDARD"
#     }
# }
```

---

### Step 3: Associate an Access Policy

Even with an access entry, you need an access policy to define permissions.

**List available policies:**

```bash
# See all available EKS access policies
aws eks list-access-policies \
    --region $REGION \
    --query 'accessPolicies[].{Name:name,Description:description}' \
    --output table

# Common policies:
# - AmazonEKSClusterAdminPolicy - Full cluster admin (recommended for workshop)
# - AmazonEKSAdminPolicy - Admin within specific namespaces
# - AmazonEKSEditPolicy - Can create/modify resources
# - AmazonEKSViewPolicy - Read-only access
```

**Associate the policy:**

```bash
# For workshop participants, give cluster admin access
aws eks associate-access-policy \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
    --access-scope type=cluster

# Output confirms association:
# {
#     "clusterName": "shared-workshop-cluster",
#     "principalArn": "arn:aws:iam::123456789012:user/eks-username",
#     "associatedAccessPolicy": {
#         "policyArn": "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
#         "accessScope": {
#             "type": "cluster"
#         },
#         "associatedAt": "2024-12-04T12:05:00+00:00"
#     }
# }
```

**For namespace-specific access** (more restrictive):

```bash
# Grant access only to specific namespaces
aws eks associate-access-policy \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy" \
    --access-scope type=namespace,namespaces=default,dev,staging
```

---

### Step 4: Verify Access

**Participant should now test:**

```bash
# Update kubeconfig (if not already done)
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1

# Test access
kubectl get nodes

# Should now work! Expected output:
# NAME                                                STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123.ap-southeast-1.compute.internal      Ready    <none>   2d    v1.28.x
# ip-10-0-2-234.ap-southeast-1.compute.internal      Ready    <none>   2d    v1.28.x
```

## 🎓 Understanding Access Policies

### Policy Comparison

| Policy                          | Access Level                 | Use Case                         |
| ------------------------------- | ---------------------------- | -------------------------------- |
| **AmazonEKSClusterAdminPolicy** | Full cluster admin           | Workshop training, trusted users |
| **AmazonEKSAdminPolicy**        | Admin in specific namespaces | Team leads, namespace admins     |
| **AmazonEKSEditPolicy**         | Create/modify resources      | Developers, engineers            |
| **AmazonEKSViewPolicy**         | Read-only access             | Viewers, auditors                |

### What Can Users Do With Each Policy?

**AmazonEKSClusterAdminPolicy (Cluster-wide admin):**

```
✅ Create/delete namespaces
✅ Manage all resources in all namespaces
✅ View and manage nodes
✅ Create cluster roles and bindings
✅ Full access to everything
```

**AmazonEKSAdminPolicy (Namespace admin):**

```
✅ Full access within assigned namespaces
✅ Create/delete pods, deployments, services
✅ View namespace-level resources
❌ Cannot create namespaces
❌ Cannot view other namespaces
❌ Cannot manage cluster-level resources
```

**AmazonEKSEditPolicy (Developer):**

```
✅ Create/modify deployments, services, configmaps
✅ View logs and describe resources
❌ Cannot delete namespaces
❌ Cannot modify RBAC
❌ Limited administrative actions
```

**AmazonEKSViewPolicy (Read-only):**

```
✅ View resources (get, list, watch)
✅ Read logs
❌ Cannot create anything
❌ Cannot modify anything
❌ Cannot delete anything
```

---

## 🚨 Common Troubleshooting Scenarios

### Issue 1: "Access entry already exists"

**Error when creating access entry:**

```
An error occurred (ResourceInUseException): Access Entry already exists
```

**Solution:**  
Skip creation, just check if policy is associated:

```bash
# Check current policies
aws eks list-associated-access-policies \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN"

# If empty, associate a policy (see Step 3 above)
```

---

### Issue 2: "Access entry exists but still getting Unauthorized"

**You created the access entry but participant still can't access.**

**Reason:**  
Access entry exists but NO POLICY is associated.

**Check:**

```bash
# This should return policies, not an empty list
aws eks list-associated-access-policies \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN"

# If "associatedAccessPolicies": [] is empty,
# then NO policies are attached!
```

**Solution:**  
Associate a policy (Step 3 above).

---

### Issue 3: Wrong AWS profile being used

**Error:** User configured but kubectl still shows unauthorized.

**Check which AWS identity kubectl is using:**

```bash
# Participant should run this
aws sts get-caller-identity

# Output should show:
# {
#     "UserId": "AIDASAMPLEUSERID",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/eks-username"
# }

# If this shows wrong user/role, configure correct profile:
aws configure --profile correct-profile
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --profile correct-profile
```

---

### Issue 4: Access works for some operations but not others

**Symptom:** Can view resources but can't create/delete.

**Reason:** User has **AmazonEKSViewPolicy** instead of **AmazonEKSEditPolicy** or **AmazonEKSClusterAdminPolicy**.

**Check current policy:**

```bash
aws eks list-associated-access-policies \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --query 'associatedAccessPolicies[].policyArn'
```

**Update to higher permission policy:**

```bash
# First, disassociate the current policy
aws eks disassociate-access-policy \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

# Then associate the desired policy
aws eks associate-access-policy \
    --cluster-name $CLUSTER_NAME \
    --region $REGION \
    --principal-arn "$USER_ARN" \
    --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
    --access-scope type=cluster
```

---

## 📋 Quick Reference Commands

### Administrator Commands

```bash
# List all users with access
aws eks list-access-entries \
    --cluster-name <cluster-name> \
    --region <region>

# Check specific user
aws eks describe-access-entry \
    --cluster-name <cluster-name> \
    --region <region> \
    --principal-arn "<user-arn>"

# Grant cluster admin access
aws eks create-access-entry \
    --cluster-name <cluster-name> \
    --region <region> \
    --principal-arn "<user-arn>"

aws eks associate-access-policy \
    --cluster-name <cluster-name> \
    --region <region> \
    --principal-arn "<user-arn>" \
    --policy-arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" \
    --access-scope type=cluster

# Remove access
aws eks disassociate-access-policy \
    --cluster-name <cluster-name> \
    --region <region> \
    --principal-arn "<user-arn>" \
    --policy-arn "<policy-arn>"

aws eks delete-access-entry \
    --cluster-name <cluster-name> \
    --region <region> \
    --principal-arn "<user-arn>"
```

### Participant Commands

```bash
# Check your AWS identity
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig \
    --name <cluster-name> \
    --region <region>

# Test access
kubectl get nodes
kubectl get namespaces
kubectl auth can-i get pods
kubectl auth can-i create deployments
kubectl auth can-i '*' '*' --all-namespaces  # Check if cluster admin
```

---

## 🔄 Migration: ConfigMap to Access Entries

If your cluster was using CONFIG_MAP mode and you're migrating:

### Step 1: Check Current Mode

```bash
aws eks describe-cluster \
    --name <cluster-name> \
    --region <region> \
    --query 'cluster.accessConfig.authenticationMode'
```

### Step 2: Update to Hybrid Mode (Safe)

```bash
# First move to hybrid mode (both methods work)
aws eks update-cluster-config \
    --name <cluster-name> \
    --region <region> \
    --access-config authenticationMode=API_AND_CONFIG_MAP

# Wait for update to complete (5-10 minutes)
aws eks describe-cluster \
    --name <cluster-name> \
    --region <region> \
    --query 'cluster.status'
```

### Step 3: Create Access Entries

Create access entries for all users (while ConfigMap still works as backup).

### Step 4: Test Access Entries

Verify all users can access via access entries.

### Step 5: Switch to API-Only (Optional)

```bash
# Once verified, switch to API-only mode
aws eks update-cluster-config \
    --name <cluster-name> \
    --region <region> \
    --access-config authenticationMode=API

# ConfigMap (aws-auth) will no longer be used
```

---

## ✅ Best Practices

### For Workshop Administrators

1. **Create access entries during initial setup**  
   Don't wait for participants to report issues.

2. **Use API or API_AND_CONFIG_MAP mode**  
   New clusters should use API mode for better management.

3. **Grant appropriate access level**

   - Workshop/Training: `AmazonEKSClusterAdminPolicy`
   - Production: Use more restrictive policies

4. **Document the process**  
   Add this to your workshop setup checklist.

5. **Test with one participant first**  
   Before granting access to all participants.

### For Participants

1. **Verify AWS credentials**  
   Always check `aws sts get-caller-identity` first.

2. **Use the correct AWS profile**  
   Add `--profile <name>` if using multiple accounts.

3. **Report access issues immediately**  
   Don't spend hours troubleshooting alone.

4. **Understand your access level**  
   Know what you can and cannot do in the cluster.

---

## 📚 Additional Resources

- [EKS Access Entries Official Documentation](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [EKS Access Policies](https://docs.aws.amazon.com/eks/latest/userguide/access-policies.html)
- [Granting access to EKS cluster](https://docs.aws.amazon.com/eks/latest/userguide/grant-k8s-access.html)
- [EKS Authentication Modes](https://docs.aws.amazon.com/eks/latest/userguide/grant-k8s-access.html#set-cam)

---

## 🎯 Summary

**The Problem:**

- IAM user exists ✅
- IAM permissions granted ✅
- EKS access entry missing ❌
- OR access policy not associated ❌

**The Solution:**

1. Create EKS access entry for IAM user
2. Associate an EKS access policy (e.g., AmazonEKSClusterAdminPolicy)
3. Participant updates kubeconfig
4. Access granted! ✅

**Remember:**  
AWS IAM permissions ≠ Kubernetes cluster access  
You need BOTH configured!

---

**Next:** Return to [05-PARTICIPANT-ACCESS.md](05-PARTICIPANT-ACCESS.md) if using ConfigMap mode, or proceed with your workshop activities.
