# Safety Guidelines for Shared EKS Cluster

**⚠️ CRITICAL: READ THIS BEFORE USING THE CLUSTER ⚠️**

This document contains essential safety practices for working in the shared EKS environment. **All 7 participants** have full administrative access, which means your actions can affect everyone else.

---

## 🚨 Golden Rules

### Rule #1: When in Doubt, ASK!
If you're not 100% sure what a command will do, ask the group or workshop admin BEFORE running it.

### Rule #2: YOU CAN DELETE EVERYTHING
With system:masters access, you have the power to:
- Delete the entire cluster
- Delete other participants' work
- Disrupt all running applications
- Use all cluster resources

**With great power comes great responsibility!**

### Rule #3: Communication is Key
Always announce in the team chat before:
- Creating/deleting node groups
- Scaling beyond 4 total nodes
- Creating large deployments (>5 replicas)
- Performing cluster-wide operations

---

## ✅ Safe Practices

### 1. Namespace Isolation

**DO:**
```bash
# Always work in your personal namespace
kubectl create namespace charles-workspace
kubectl config set-context --current --namespace=charles-workspace

# Deploy to your namespace
kubectl apply -f deployment.yaml -n charles-workspace

# View only your resources
kubectl get pods -n charles-workspace
```

**DON'T:**
```bash
# Don't deploy to default namespace
kubectl apply -f deployment.yaml  # BAD - uses default

# Don't deploy to others' namespaces
kubectl apply -f deployment.yaml -n joshua-workspace  # BAD!

# Don't delete others' namespaces
kubectl delete namespace robert-workspace  # BAD!
```

---

### 2. Resource Naming Conventions

**Use this pattern for ALL resources:**

```
<your-name>-<resource-type>-<description>

Examples:
- charles-webapp-deployment
- joshua-api-service
- robert-postgres-db
```

**Why this matters:**
- Easy to identify who owns what
- Prevents naming conflicts
- Helps with troubleshooting
- Enables clean cleanup

**YAML Example:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: charles-workspace  # ✅ Prefixed with name
  labels:
    owner: charles
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: charles-webapp  # ✅ Prefixed with name
  namespace: charles-workspace
  labels:
    app: charles-webapp
    owner: charles
```

---

### 3. Resource Limits

**ALWAYS set resource requests and limits on pods:**

```yaml
resources:
  requests:      # Guaranteed resources
    cpu: 100m    # 0.1 CPU cores
    memory: 128Mi
  limits:        # Maximum allowed
    cpu: 200m    # 0.2 CPU cores
    memory: 256Mi
```

**Why this matters:**
- Prevents one person hogging all resources
- Ensures fair distribution
- Cluster remains stable
- Others can deploy their apps

**Cluster Capacity:**
```
Total Available (2 nodes):
├── CPU: ~3.4 vCPU
├── Memory: ~6.4 GB
└── Fair share per person: ~0.5 vCPU, ~900 MB

Your apps should use:
├── Small pod: 100m CPU, 128Mi RAM
├── Medium pod: 200m CPU, 256Mi RAM
├── Don't exceed 3-4 pods without asking!
```

---

### 4. Node Management

**Coordinate Before Scaling:**

```bash
# ✅ GOOD: Check current capacity first
kubectl get nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# ✅ GOOD: Announce in chat before creating nodes
# "Hey team, I need to test node scaling. Creating 1 new node. OK?"

# ❌ BAD: Creating nodes without announcement
aws eks create-nodegroup ...  # DON'T do this without asking!

# ❌ BAD: Deleting shared node group
aws eks delete-nodegroup --nodegroup-name training-nodes  # NEVER!
```

**Node Group Naming:**
- If creating your own node group: `<name>-nodes`
- Example: `charles-test-nodes`
- Always use Spot instances (cheaper)
- Delete when done testing!

---

### 5. ECR Image Management

**Tagging Convention:**

```
<username>-<appname>-<version>

Examples:
✅ charles-webapp-v1
✅ joshua-frontend-v2
✅ robert-api-v3

❌ webapp (too generic)
❌ myapp-v1 (missing username)
✅ Don't overwrite others' images!
```

**Commands:**
```bash
# ✅ GOOD: Tag with your name
docker tag myapp:latest <ecr-uri>:charles-webapp-v1
docker push <ecr-uri>:charles-webapp-v1

# ❌ BAD: Generic tag (conflicts possible)
docker tag myapp:latest <ecr-uri>:webapp-v1

# ✅ GOOD: View all images
aws ecr list-images --repository-name eks-workshop-apps

# ⚠️ CAREFUL: Deleting images
# Make sure it's YOUR image before deleting!
aws ecr batch-delete-image \
  --repository-name eks-workshop-apps \
  --image-ids imageTag=charles-webapp-v1
```

---

## ❌ What NOT to Do

### Critical - NEVER Do These:

```bash
# 1. NEVER delete the cluster
aws eks delete-cluster --name shared-workshop-cluster  # ❌ NEVER!

# 2. NEVER delete ALL node groups
aws eks delete-nodegroup --cluster-name shared-workshop-cluster --nodegroup-name training-nodes  # ❌ NEVER!

# 3. NEVER delete system namespaces
kubectl delete namespace kube-system  # ❌ NEVER!
kubectl delete namespace kube-public  # ❌ NEVER!
kubectl delete namespace default  # ❌ NEVER!

# 4. NEVER delete other participants' namespaces
kubectl delete namespace joshua-workspace  # ❌ NEVER!

# 5. NEVER modify system pods
kubectl delete pod coredns-xxx -n kube-system  # ❌ NEVER!

# 6. NEVER use ALL cluster capacity
kubectl scale deployment myapp --replicas=50  # ❌ NEVER!

# 7. NEVER deploy without resource limits
# (see resource limits section above)
```

---

### Use These Commands Carefully:

```bash
# ⚠️ ALWAYS specify namespace
kubectl delete deployment webapp -n charles-workspace  # ✅ Safe
kubectl delete deployment webapp  # ❌ Deletes from default!

# ⚠️ ALWAYS check before deleting
kubectl get all -n charles-workspace  # Check what exists
kubectl delete -f deployment.yaml -n charles-workspace  # Then delete

# ⚠️ ALWAYS confirm node operations
kubectl get nodes  # See current nodes
kubectl cordon <node-name>  # Mark for maintenance
kubectl drain <node-name> --ignore-daemonsets  # Only if coordinated!

# ⚠️ ALWAYS check cluster events if something fails
kubectl get events --sort-by='.lastTimestamp' | head -20
```

---

## 🗣️ Communication Protocols

### Team Chat Requirements

**Always announce these in team chat BEFORE doing them:**

1. **Creating Node Groups**
   ```
   Message: "Creating 1 t3.medium node for testing. 
            Node group name: charles-test-nodes. 
            Will delete after 1 hour. OK?"
   ```

2. **Scaling Beyond 4 Nodes**
   ```
   Message: "Need to scale to 5 total nodes for load testing. 
            OK with everyone?"
   ```

3. **Large Deployments**
   ```
   Message: "Deploying 5 replicas of my app (500m CPU, 512Mi RAM each). 
            Using 2.5 vCPU total. OK?"
   ```

4. **Testing Destructive Operations**
   ```
   Message: "Testing pod disruption budgets - will drain node 1. 
            Might affect your running pods. OK to proceed?"
   ```

### Response Time

- Wait 5-10 minutes for responses
- If urgent, call out specific people
- If no response and non-critical, proceed carefully
- If critical operation, wait for explicit approval

---

## 🔍 Monitoring & Visibility

### Check Cluster Status Before Deploying

```bash
# 1. Check node capacity
kubectl top nodes

# Example output:
# NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
# node-1      500m         25%    2Gi             50%       
# node-2      400m         20%    1.5Gi           37%

# 2. Check running pods
kubectl get pods --all-namespaces | grep -v kube-system

# 3. Check resource quotas (if implemented)
kubectl get resourcequota --all-namespaces

# 4. Check events for issues
kubectl get events --sort-by='.lastTimestamp' | head -20
```

### Monitor Your Own Resources

```bash
# Your namespace resources
kubectl get all -n charles-workspace

# Your pod resource usage
kubectl top pods -n charles-workspace

# Your pod logs
kubectl logs -f <pod-name> -n charles-workspace

# Your pod events
kubectl describe pod <pod-name> -n charles-workspace
```

---

## 🛟 Recovery Procedures

### If You Make a Mistake

**Stay Calm and:**

1. **Immediately announce in team chat**
   ```
   "ERROR: I accidentally deleted joshua-workspace namespace. 
    Sorry Joshua! Can help recover?"
   ```

2. **Document what happened**
   - What command did you run?
   - What was the intended action?
   - What actually happened?

3. **Check the impact**
   ```bash
   kubectl get all --all-namespaces
   kubectl get nodes
   kubectl get events
   ```

4. **Ask for help**
   - Workshop admin
   - Other participants
   - Don't try to fix alone if unsure!

---

### If Someone Else Breaks Something

**Be Supportive:**

1. Mistakes happen - we're all learning
2. Help troubleshoot together
3. Document learnings for everyone
4. No blame, just learn and improve

**If Cluster is Broken:**
- Notify workshop admin immediately
- Document error messages
- May need to recreate cluster (admin task)
- Save your YAML files for redeployment

---

## ✅ Pre-Flight Checklist

Before running ANY kubectl/aws command, ask yourself:

- [ ] Am I in the correct namespace?
- [ ] Do I have resource limits set?
- [ ] Is my resource name prefixed with my username?
- [ ] Have I checked cluster capacity?
- [ ] Do I need to announce this action?
- [ ] Am I 100% sure this won't affect others?
- [ ] Have I tested this in a smaller scale first?

**If you answered NO to any question, STOP and reconsider!**

---

## 💡 Best Practices Summary

### DO:
- ✅ Work in your personal namespace
- ✅ Prefix all resources with your name
- ✅ Set resource requests/limits
- ✅ Communicate before major actions
- ✅ Clean up resources when done
- ✅ Monitor cluster capacity
- ✅ Ask if unsure
- ✅ Help others when they need it

### DON'T:
- ❌ Delete the cluster
- ❌ Delete others' resources
- ❌ Use all cluster capacity
- ❌ Deploy without limits
- ❌ Modify system components
- ❌ Work in default namespace
- ❌ Make changes without announcing
- ❌ Leave resources running overnight

---

## 📞 Getting Help

### Issues and Questions

**Technical Issues:**
1. Check [REFERENCE/TROUBLESHOOTING.md](REFERENCE/TROUBLESHOOTING.md)
2. Ask in team chat
3. Contact workshop admin

**Permission Questions:**
1. Check [REFERENCE/PERMISSIONS-REFERENCE.md](REFERENCE/PERMISSIONS-REFERENCE.md)
2. Ask workshop admin

**Cluster Status:**
```bash
# Check overall health
kubectl get componentstatuses
kubectl get nodes
kubectl top nodes

# Check for issues
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

---

## 🎓 Learning from This

### Why These Guidelines Matter

**Real-World Parallels:**

This shared environment simulates real production scenarios:

```
Workshop Cluster          →    Company Production Cluster
7 participants           →    10-100 developers
Personal namespaces      →    Team namespaces
Communication required   →    Change management process
Resource limits          →    Resource quotas & policies
Coordination             →    Release scheduling
```

### Skills You're Building

- **Technical:** Kubernetes, AWS, resource management
- **Collaboration:** Communication, coordination, teamwork
- **Responsibility:** Impact awareness, careful operations
- **Problem-solving:** Troubleshooting, recovery, adaptation

These are **essential skills** for DevOps/Platform Engineering roles!

---

## 🤝 Remember

You're part of a **team learning environment**. Your success depends on:

1. **Respecting others' work**
2. **Communicating proactively**
3. **Being helpful when others struggle**
4. **Learning from mistakes together**
5. **Sharing knowledge and tips**

**Have fun, learn lots, and be considerate!** 🚀

---

## Quick Reference

```bash
# Set up your workspace
kubectl create namespace <your-name>-workspace
kubectl config set-context --current --namespace=<your-name>-workspace

# Check before deploying
kubectl top nodes
kubectl get all --all-namespaces

# Deploy safely
kubectl apply -f deployment.yaml -n <your-name>-workspace

# Clean up when done
kubectl delete -f deployment.yaml -n <your-name>-workspace

# Monitor
kubectl get pods -n <your-name>-workspace -w
kubectl logs -f <pod-name> -n <your-name>-workspace
```

---

**By following these guidelines, we can all learn effectively in a safe, collaborative environment!**

