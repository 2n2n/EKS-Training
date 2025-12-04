# Activity 1: Connect to the Shared EKS Cluster

**For:** Workshop Participants  
**Time:** 10-15 minutes  
**Prerequisites:** AWS CLI and kubectl installed (see [00-SETUP-PREREQUISITES.md](../00-SETUP-PREREQUISITES.md))

Welcome to your first hands-on activity! You'll connect to the shared EKS cluster that the workshop admin has set up for everyone.

---

## 🎯 What You'll Learn

- Configure AWS credentials on your machine
- Connect kubectl to the EKS cluster
- Verify your access and permissions
- Explore the cluster structure

---

## ⚠️ Before You Start

**READ THIS:** [../SAFETY-GUIDELINES.md](../SAFETY-GUIDELINES.md)

You have **full admin access** to a shared cluster. Your actions affect 6 other participants!

---

## Step 1: Get Your Credentials

The workshop admin will provide you with:

| Information       | Example                   | Your Value   |
| ----------------- | ------------------------- | ------------ |
| IAM Username      | `eks-charles`             | ****\_\_**** |
| Access Key ID     | `AKIA...`                 | ****\_\_**** |
| Secret Access Key | `wJalr...`                | ****\_\_**** |
| AWS Region        | `ap-southeast-1`          | ****\_\_**** |
| Cluster Name      | `shared-workshop-cluster` | ****\_\_**** |

**Keep these credentials safe!** Don't share them publicly.

---

## Step 2: Configure AWS Credentials

Open your terminal and run:

```bash
aws configure
```

Enter the values when prompted:

```
AWS Access Key ID [None]: <your-access-key-id>
AWS Secret Access Key [None]: <your-secret-access-key>
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

### Verify AWS Configuration

```bash
# Check your identity
aws sts get-caller-identity
```

**Expected output:**

```json
{
  "UserId": "AIDAXXXXXXXXXXXXXXXXX",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/eks-charles"
}
```

✅ **Success!** You should see your IAM username in the ARN.

---

## Step 3: Connect to EKS Cluster

Run this command to configure kubectl:

```bash
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1
```

**Expected output:**

```
Added new context arn:aws:eks:ap-southeast-1:123456789012:cluster/shared-workshop-cluster to /Users/yourname/.kube/config
```

### What This Does

- Downloads cluster certificate
- Adds cluster endpoint to your kubeconfig
- Sets up authentication
- Makes this your current kubectl context

---

## Step 4: Verify Cluster Connection

### Check Nodes

```bash
kubectl get nodes
```

**Expected output (2 nodes):**

```
NAME                                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.ap-southeast-1.compute.internal Ready    <none>   1h    v1.28.x
ip-10-0-2-234.ap-southeast-1.compute.internal Ready    <none>   1h    v1.28.x
```

✅ If you see **2 nodes** with STATUS=**Ready**, you're connected!

### Check Namespaces

```bash
kubectl get namespaces
```

**Expected output:**

```
NAME              STATUS   AGE
default           Active   1h
kube-node-lease   Active   1h
kube-public       Active   1h
kube-system       Active   1h
```

You might also see namespaces created by other participants.

### Check Your Permissions

```bash
# Can you view system pods? (Tests admin access)
kubectl get pods -n kube-system
```

**Expected output:** List of system pods (aws-node, coredns, kube-proxy)

✅ If this works, you have **full admin access** to the cluster!

---

## Step 5: Explore the Cluster

### View Cluster Information

```bash
# Cluster endpoint
kubectl cluster-info

# Kubernetes version
kubectl version --short

# Current context
kubectl config current-context
```

### View Node Details

```bash
# Detailed node info
kubectl get nodes -o wide

# Shows:
# - Internal IP
# - External IP (public)
# - OS Image
# - Container runtime
```

### Check Available Resources

```bash
# See what resources the cluster can manage
kubectl api-resources | head -20

# Check cluster capacity
kubectl describe nodes | grep -A 5 "Allocatable"
```

---

## Step 6: Set Up Your Namespace (Preview)

Create a personal namespace to work in:

```bash
# Replace 'charles' with YOUR name (lowercase)
kubectl create namespace charles-workspace
```

**Expected output:**

```
namespace/charles-workspace created
```

Set it as your default:

```bash
kubectl config set-context --current --namespace=charles-workspace
```

**Now all your kubectl commands will use your namespace by default!**

Verify:

```bash
kubectl config view --minify | grep namespace
```

for windows:

```bash
kubectl config view --minify | findstr "namespace"
```

---

## ✅ Validation Checklist

Before proceeding, confirm:

- [ ] `aws sts get-caller-identity` shows your username
- [ ] `kubectl get nodes` shows 2 nodes with STATUS=Ready
- [ ] `kubectl get pods -n kube-system` lists system pods
- [ ] Created your personal namespace
- [ ] Set namespace as default context

---

## 🚨 Troubleshooting

### Issue: "Unable to locate credentials"

**Error:**

```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

**Solution:**

```bash
# Re-run aws configure
aws configure

# Verify credentials file exists
cat ~/.aws/credentials
```

---

### Issue: "Unable to connect to the server"

**Error:**

```
Unable to connect to the server: dial tcp: lookup xxxxx on 8.8.8.8:53: no such host
```

**Solution:**

```bash
# Check your internet connection
ping google.com

# Re-run update-kubeconfig
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1

# Verify cluster exists
aws eks describe-cluster --name shared-workshop-cluster --region ap-southeast-1
```

---

### Issue: "Unauthorized" Error

**Error:**

```
error: You must be logged in to the server (Unauthorized)
```

**Solution:**

```bash
# Verify you're using correct credentials
aws sts get-caller-identity

# If wrong user, reconfigure:
aws configure

# Then re-run update-kubeconfig
aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1
```

**Still not working?** Contact the workshop admin - they may need to add you to the aws-auth ConfigMap.

---

### Issue: "No nodes found"

**Cause:** Cluster has no worker nodes yet.

**Solution:**

- Wait - admin may still be setting up
- Or, you'll create nodes in a later activity!

---

## 💡 Quick Commands Reference

```bash
# AWS identity
aws sts get-caller-identity

# Connect to cluster
aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1

# View nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>

# View namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace <your-name>-workspace

# Set default namespace
kubectl config set-context --current --namespace=<your-name>-workspace

# Check current context
kubectl config current-context
kubectl config view --minify
```

---

## 🎓 What You Learned

- ✅ How to configure AWS CLI credentials
- ✅ How to connect kubectl to an EKS cluster
- ✅ How to verify cluster access
- ✅ How to create and set a default namespace
- ✅ Basic cluster exploration commands

---

## 🚀 Next Activity

You're connected! Now create your workspace:

**Next:** [02-NAMESPACE-MANAGEMENT.md](02-NAMESPACE-MANAGEMENT.md) - Create and manage your personal namespace

---

## 📚 Additional Resources

- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
