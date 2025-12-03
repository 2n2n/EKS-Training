# Activity 2: Namespace Management

**For:** Workshop Participants  
**Time:** 15 minutes  
**Prerequisites:** Completed [01-CONNECT-TO-CLUSTER.md](01-CONNECT-TO-CLUSTER.md)

Learn how to create and manage your personal namespace in the shared cluster.

---

## 🎯 What You'll Learn

- Create your own namespace
- Set namespace as default
- Understand namespace isolation
- Manage namespace resources
- Delete namespaces safely

---

## Why Namespaces?

In a shared cluster, namespaces provide **logical isolation**:

```
Shared Cluster
├── kube-system (Kubernetes system - DON'T TOUCH!)
├── default (shared default - avoid using)
├── charles-workspace (YOUR apps)
├── joshua-workspace (Joshua's apps)
├── robert-workspace (Robert's apps)
└── ... (other participants)
```

**Benefits:**
- Organize your resources separately
- Avoid naming conflicts with others
- Easy cleanup (delete namespace = delete all your apps)
- Can apply resource quotas

---

## Step 1: View Existing Namespaces

### List All Namespaces

```bash
kubectl get namespaces
```

**Expected output:**
```
NAME              STATUS   AGE
default           Active   2h
kube-node-lease   Active   2h
kube-public       Active   2h
kube-system       Active   2h
```

You may also see other participants' namespaces.

### Describe a Namespace

```bash
kubectl describe namespace default
```

**Shows:**
- Labels
- Annotations
- Resource quotas (if any)
- Status

---

## Step 2: Create Your Personal Namespace

### Create Namespace

**Replace `charles` with YOUR name (lowercase, no spaces):**

```bash
kubectl create namespace charles-workspace
```

**Expected output:**
```
namespace/charles-workspace created
```

### Verify Creation

```bash
kubectl get namespaces | grep charles
```

**Output:**
```
charles-workspace   Active   5s
```

### Alternative: Create with YAML

```yaml
# Save as my-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: charles-workspace
  labels:
    owner: charles
    purpose: workshop
    team: eks-training
```

```bash
kubectl apply -f my-namespace.yaml
```

---

## Step 3: Set as Default Namespace

### Set Default Context

```bash
kubectl config set-context --current --namespace=charles-workspace
```

**Now all your commands use this namespace by default!**

### Verify Default

```bash
# Check current namespace
kubectl config view --minify | grep namespace

# Should show:
# namespace: charles-workspace
```

### Test Default

```bash
# This now queries YOUR namespace
kubectl get pods

# Output:
# No resources found in charles-workspace namespace.
```

---

## Step 4: Work with Namespaces

### Specifying Namespace Explicitly

Even with a default set, you can specify namespace explicitly:

```bash
# Your namespace
kubectl get pods -n charles-workspace

# System namespace
kubectl get pods -n kube-system

# All namespaces
kubectl get pods --all-namespaces
kubectl get pods -A  # Short form
```

### Best Practice: Always Be Explicit

For safety in shared environments, consider always using `-n`:

```bash
# Explicit is safer
kubectl apply -f deployment.yaml -n charles-workspace

# vs relying on default (could apply to wrong namespace!)
kubectl apply -f deployment.yaml
```

---

## Step 5: View Resources in Your Namespace

### List All Resources

```bash
# All resources in your namespace
kubectl get all -n charles-workspace

# Currently empty:
# No resources found in charles-workspace namespace.
```

### After Deploying Apps (Later Activities)

```bash
kubectl get all -n charles-workspace

# Will show:
# NAME                            READY   STATUS    RESTARTS   AGE
# pod/myapp-xxx                   1/1     Running   0          5m
# 
# NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
# service/myapp-svc    NodePort    10.100.x.x     <none>        80:30080/TCP
```

---

## Step 6: Namespace Operations

### View Namespace Details

```bash
kubectl describe namespace charles-workspace
```

### Add Labels to Namespace

```bash
kubectl label namespace charles-workspace environment=development
kubectl label namespace charles-workspace owner=charles

# Verify
kubectl get namespace charles-workspace --show-labels
```

### View Namespace Events

```bash
kubectl get events -n charles-workspace
```

---

## ⚠️ Deleting Namespaces

### Delete Your Namespace

**WARNING:** This deletes **ALL resources** in the namespace!

```bash
kubectl delete namespace charles-workspace
```

**What gets deleted:**
- All pods
- All deployments
- All services
- All configmaps
- All secrets
- Everything in that namespace!

### Recreate After Deletion

```bash
# Create it again
kubectl create namespace charles-workspace

# Reset default
kubectl config set-context --current --namespace=charles-workspace
```

---

## 🚫 DO NOT Delete These!

**System namespaces - NEVER delete:**

```bash
# ❌ NEVER DO THIS:
kubectl delete namespace kube-system    # BREAKS CLUSTER!
kubectl delete namespace kube-public    # System namespace
kubectl delete namespace kube-node-lease # Node health checks
kubectl delete namespace default        # Can't delete anyway

# ❌ NEVER delete others' namespaces:
kubectl delete namespace joshua-workspace  # NOT YOURS!
```

---

## 💡 Namespace Naming Convention

**For this workshop, use:**

```
Format: <your-name>-workspace
        <your-name>-<purpose>

Examples:
✅ charles-workspace     (main workspace)
✅ charles-testing       (for experiments)
✅ charles-production    (if simulating prod)

❌ my-namespace          (too generic)
❌ test                  (might conflict)
❌ workspace             (no ownership)
```

---

## ✅ Validation Checklist

- [ ] Created personal namespace `<your-name>-workspace`
- [ ] Set namespace as default context
- [ ] Can list namespaces
- [ ] Understand what NOT to delete
- [ ] Know how to specify namespace with `-n`

---

## 📋 Quick Commands Reference

```bash
# CREATE namespace
kubectl create namespace <name>

# LIST namespaces
kubectl get namespaces
kubectl get ns  # Short form

# DESCRIBE namespace
kubectl describe namespace <name>

# SET default namespace
kubectl config set-context --current --namespace=<name>

# VIEW current namespace
kubectl config view --minify | grep namespace

# LABEL namespace
kubectl label namespace <name> key=value

# GET resources in namespace
kubectl get all -n <namespace>
kubectl get pods -n <namespace>

# DELETE namespace (CAREFUL!)
kubectl delete namespace <name>

# ALL namespaces
kubectl get pods --all-namespaces
kubectl get pods -A
```

---

## 🎓 What You Learned

- ✅ How to create namespaces
- ✅ How to set default namespace
- ✅ How to work across namespaces
- ✅ Namespace isolation concepts
- ✅ What NOT to delete in shared cluster

---

## 🚀 Next Activity

Now let's add compute capacity to the cluster!

**Next:** [03-NODE-GROUP-MANAGEMENT.md](03-NODE-GROUP-MANAGEMENT.md) - Create and manage worker nodes

---

## 📚 Additional Resources

- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Namespace Best Practices](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#when-to-use-multiple-namespaces)

