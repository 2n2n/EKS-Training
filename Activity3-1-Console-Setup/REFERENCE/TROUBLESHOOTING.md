# Troubleshooting Guide

Common issues and solutions for the EKS workshop.

---

## 📋 Table of Contents

- [Connection Issues](#connection-issues)
- [Pod Issues](#pod-issues)
- [Service Issues](#service-issues)
- [Node Issues](#node-issues)
- [ECR Issues](#ecr-issues)
- [Permission Issues](#permission-issues)
- [Shared Environment Conflicts](#shared-environment-conflicts)

---

## Connection Issues

### Can't Connect to Cluster

**Symptom:**

```
Unable to connect to the server: dial tcp: lookup xxx on xxx: no such host
```

**Solutions:**

1. **Check AWS credentials:**

```bash
aws sts get-caller-identity
# Should show your user ARN
```

2. **Update kubeconfig:**

```bash
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1
```

3. **Check cluster exists:**

```bash
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1
```

4. **Check region:**

```bash
aws configure get region
# Should be: ap-southeast-1
```

---

### Unauthorized Error

**Symptom:**

```
error: You must be logged in to the server (Unauthorized)

Your current IAM principal doesn't have access to Kubernetes objects on this cluster.
This might be due to the current principal not having an IAM access entry with
permissions to access the cluster.
```

**This is the most common issue!**

**⚠️ FIRST: Check cluster authentication mode:**

Your cluster might be using the modern **Access Entries** method instead of ConfigMap.

**👉 See complete guide:** [ROOT-SETUP/06-EKS-ACCESS-ENTRIES-TROUBLESHOOTING.md](../ROOT-SETUP/06-EKS-ACCESS-ENTRIES-TROUBLESHOOTING.md)

**Quick Solutions:**

1. **Verify identity:**

```bash
aws sts get-caller-identity
# Should show your IAM user ARN
```

2. **Check if you have an access entry (ask admin to run):**

```bash
# Admin checks your access
aws eks describe-access-entry \
    --cluster-name shared-workshop-cluster \
    --region ap-southeast-1 \
    --principal-arn "arn:aws:iam::<account-id>:user/<your-username>"

# If error "ResourceNotFoundException" = you need an access entry created
# If successful but empty policies = you need a policy associated
```

3. **Re-authenticate (simple fix to try first):**

```bash
# Clear cached credentials
rm -rf ~/.kube/cache/

# Update kubeconfig
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1
```

4. **Contact administrator if issue persists:**
   - They need to create an EKS Access Entry for your IAM user
   - They need to associate an Access Policy (e.g., AmazonEKSClusterAdminPolicy)
   - See [06-EKS-ACCESS-ENTRIES-TROUBLESHOOTING.md](../ROOT-SETUP/06-EKS-ACCESS-ENTRIES-TROUBLESHOOTING.md) for admin instructions

---

### No Nodes Found

**Symptom:**

```
kubectl get nodes
# No resources found
```

**Solutions:**

1. **Check node group status:**

```bash
aws eks list-nodegroups \
    --cluster-name shared-workshop-cluster \
    --region ap-southeast-1

aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \
    --region ap-southeast-1 \
    --query 'nodegroup.status'
```

2. **Wait for nodes (takes ~5-10 min after creation)**

3. **Check node group health issues in AWS Console:**
   - EKS → Cluster → Compute → Node group → Health issues

---

## Pod Issues

### Pods Stuck in Pending

**Symptom:**

```
NAME          READY   STATUS    RESTARTS   AGE
my-pod-xxx    0/1     Pending   0          5m
```

**Diagnose:**

```bash
kubectl describe pod <pod-name> -n <namespace>
# Look at Events section
```

**Common Causes & Solutions:**

1. **Insufficient resources:**

```
Events:
  Warning  FailedScheduling  ... 0/2 nodes are available: 2 Insufficient cpu

# Solution: Scale node group or reduce resource requests
```

2. **No matching nodes (nodeSelector/affinity):**

```
Events:
  Warning  FailedScheduling  ... 0/2 nodes are available: 2 node(s) didn't match

# Solution: Check nodeSelector labels, remove if not needed
```

3. **PVC not bound:**

```
Events:
  Warning  FailedScheduling  ... persistentvolumeclaim not bound

# Solution: Create PV or use dynamic provisioning
```

---

### Pods in CrashLoopBackOff

**Symptom:**

```
NAME          READY   STATUS             RESTARTS   AGE
my-pod-xxx    0/1     CrashLoopBackOff   5          5m
```

**Diagnose:**

```bash
# Check logs
kubectl logs <pod-name> -n <namespace>

# Check previous container logs
kubectl logs <pod-name> --previous -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>
```

**Common Causes:**

1. **Application error:** Check logs for error messages
2. **Missing config:** Check environment variables, configmaps
3. **Wrong command:** Check container command/args
4. **Health check failing:** Check liveness probe settings

---

### Pods in ImagePullBackOff

**Symptom:**

```
NAME          READY   STATUS             RESTARTS   AGE
my-pod-xxx    0/1     ImagePullBackOff   0          5m
```

**Diagnose:**

```bash
kubectl describe pod <pod-name> -n <namespace>
# Look for: Failed to pull image "xxx"
```

**Solutions:**

1. **Check image name/tag:**

```bash
# Verify image exists
aws ecr list-images --repository-name eks-workshop-apps

# Image name is case-sensitive!
```

2. **Check ECR login:**

```bash
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
```

3. **Check node role has ECR access:**

   - Node role should have `AmazonEC2ContainerRegistryReadOnly` policy

4. **For public images, check internet access:**
   - Nodes need internet access to pull from Docker Hub

---

### Pods in Error State

**Symptom:**

```
NAME          READY   STATUS    RESTARTS   AGE
my-pod-xxx    0/1     Error     0          1m
```

**Diagnose:**

```bash
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

**Common Causes:**

- Init container failed
- Main container exited with error
- Check exit code in describe output

---

## Service Issues

### Service Not Accessible (NodePort)

**Symptom:** Can't reach `http://<node-ip>:<node-port>`

**Solutions:**

1. **Verify service exists and has endpoints:**

```bash
kubectl get svc <service-name> -n <namespace>
kubectl get endpoints <service-name> -n <namespace>

# Endpoints should list pod IPs
# If empty, selector doesn't match pod labels
```

2. **Check security group:**

   - Node security group must allow NodePort range (30000-32767)
   - Check in EC2 Console → Security Groups

3. **Check node has public IP:**

```bash
kubectl get nodes -o wide
# EXTERNAL-IP should not be <none>
```

4. **Test from within cluster first:**

```bash
kubectl run test --image=curlimages/curl -it --rm -- \
    curl http://<service-name>.<namespace>.svc.cluster.local
```

---

### Service Endpoints Empty

**Symptom:**

```
kubectl get endpoints <service-name>
# Shows: <none>
```

**Cause:** Service selector doesn't match any pod labels

**Solution:**

```bash
# Check service selector
kubectl get svc <service-name> -o yaml | grep selector -A 5

# Check pod labels
kubectl get pods --show-labels -n <namespace>

# Labels must match exactly!
```

---

### Port Forward Not Working

**Symptom:**

```
kubectl port-forward svc/myservice 8080:80
# Hangs or errors
```

**Solutions:**

1. **Check service has endpoints:**

```bash
kubectl get endpoints <service-name> -n <namespace>
```

2. **Try forwarding to pod directly:**

```bash
kubectl port-forward pod/<pod-name> 8080:80 -n <namespace>
```

3. **Check local port not in use:**

```bash
lsof -i :8080
```

---

## Node Issues

### Nodes Not Joining Cluster

**Symptom:** Node group created but nodes don't appear

**Solutions:**

1. **Check node group status:**

```bash
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <nodegroup-name> \
    --region ap-southeast-1 \
    --query 'nodegroup.[status,health]'
```

2. **Check health issues in console:**

   - EKS → Cluster → Compute → Node group → Health issues

3. **Common issues:**
   - Node role missing required policies
   - Security group blocking communication
   - Subnets don't have internet access
   - IAM permissions issue

---

### Nodes in NotReady State

**Symptom:**

```
kubectl get nodes
NAME          STATUS     ROLES    AGE
ip-10-0-xxx   NotReady   <none>   5m
```

**Diagnose:**

```bash
kubectl describe node <node-name>
# Look at Conditions section
```

**Common Causes:**

- Kubelet not running on node
- Network connectivity issues
- Disk pressure / Memory pressure
- Node just starting (wait a few minutes)

---

## ECR Issues

### "no basic auth credentials"

**Symptom:**

```
Error response from daemon: no basic auth credentials
```

**Solution:**

```bash
# Re-authenticate
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

# Token valid for 12 hours
```

---

### "denied: User is not authorized"

**Symptom:**

```
denied: User: arn:aws:iam::xxx:user/eks-charles is not authorized
```

**Solutions:**

1. **Check IAM permissions:**

```bash
# Your user needs ECR permissions
aws ecr describe-repositories
# If this fails, ask admin for permissions
```

2. **Check repository policy:**
   - ECR Console → Repository → Permissions

---

### Push Fails

**Symptom:** Docker push hangs or fails

**Solutions:**

1. **Check image is tagged correctly:**

```bash
docker images | grep <your-image>
# Tag must include full ECR URI
```

2. **Re-tag if needed:**

```bash
docker tag <local-image> <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps:<tag>
```

3. **Check network connectivity:**

```bash
# Test ECR endpoint
curl https://<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/v2/
```

---

## Permission Issues

### "forbidden: User cannot..."

**Symptom:**

```
Error from server (Forbidden): pods is forbidden: User "charles" cannot list resource "pods"
```

**Solutions:**

1. **Check your permissions:**

```bash
kubectl auth can-i list pods
kubectl auth can-i create pods -n <namespace>
```

2. **Verify aws-auth mapping:**

```bash
kubectl get configmap aws-auth -n kube-system -o yaml
```

3. **Contact admin** to add you to aws-auth

---

### Can't Create Resources

**Symptom:** Permission denied when creating pods, deployments, etc.

**Check:**

```bash
# What can you do?
kubectl auth can-i --list

# Specific check
kubectl auth can-i create deployments -n <namespace>
```

---

## Shared Environment Conflicts

### Resource Name Conflicts

**Symptom:**

```
Error: services "webapp" already exists
```

**Solution:**

```bash
# Use unique names with your prefix
kubectl create deployment charles-webapp ...

# Check what exists
kubectl get all --all-namespaces | grep webapp
```

---

### Namespace Conflicts

**Symptom:** Someone else using same namespace name

**Solution:**

```bash
# Use your name in namespace
kubectl create namespace charles-workspace

# NOT generic names like:
# test, dev, staging, production
```

---

### Accidental Resource Deletion

**Prevention:**

```bash
# ALWAYS use namespace flag
kubectl delete pod xxx -n charles-workspace  ✅
kubectl delete pod xxx                        ❌

# Double check before delete
kubectl get pod xxx -n <namespace>
```

**Recovery:**

```bash
# If you deleted your own resources:
kubectl apply -f <your-yaml-file>

# If you deleted someone else's:
# Apologize and help them redeploy!
```

---

### Resource Quota Exceeded

**Symptom:**

```
Error: exceeded quota: too many pods
```

**Solution:**

- Clean up unused pods
- Scale down replicas
- Coordinate with other participants

---

## 🔧 General Debug Commands

```bash
# Full cluster state
kubectl get all --all-namespaces

# Events (sorted by time)
kubectl get events -A --sort-by='.lastTimestamp' | head -30

# Pod details
kubectl describe pod <name> -n <namespace>

# Pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> --previous -n <namespace>

# Exec into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Node details
kubectl describe node <node-name>

# Check permissions
kubectl auth can-i <verb> <resource>

# AWS identity
aws sts get-caller-identity
```

---

## 📞 Getting Help

1. **Check this guide first**
2. **Search error message online**
3. **Ask in team chat with:**
   - Exact error message
   - Command you ran
   - What you expected vs what happened
4. **Ask workshop facilitator**

---

## 🔗 Additional Resources

- [EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [kubectl Debug](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#interacting-with-running-pods)
