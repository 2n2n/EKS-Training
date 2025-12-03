# Activity 6: Testing and Validation

**For:** Workshop Participants  
**Time:** 30 minutes  
**Prerequisites:** Completed previous activities, have deployed application

Test everything you've built to ensure it works correctly.

---

## 🎯 What You'll Learn

- Test application deployment and health
- Verify service connectivity
- Test high availability and self-healing
- Monitor resources and events
- Troubleshoot common issues

---

## Step 1: Verify Deployment Health

### Check Deployment Status

```bash
# Set your namespace
export NS=charles-workspace

# Check deployment
kubectl get deployment -n $NS

# Expected: READY shows desired/actual replicas
# NAME          READY   UP-TO-DATE   AVAILABLE   AGE
# charles-app   2/2     2            2           10m
```

### Check Pod Status

```bash
# Check pods
kubectl get pods -n $NS

# All pods should show STATUS=Running
# NAME                          READY   STATUS    RESTARTS   AGE
# charles-app-xxx-yyy          1/1     Running   0          10m
# charles-app-xxx-zzz          1/1     Running   0          10m
```

### Check Pod Distribution

```bash
# See which nodes pods are on
kubectl get pods -n $NS -o wide

# Pods should be distributed across nodes
```

---

## Step 2: Test Service Connectivity

### Internal Connectivity (Within Cluster)

```bash
# Get ClusterIP
kubectl get svc -n $NS

# Test from another pod
kubectl run test-curl --image=curlimages/curl -it --rm -- \
    curl http://charles-app-svc.$NS.svc.cluster.local

# Expected: HTML response from your app
```

### External Connectivity (NodePort)

```bash
# Get NodePort and Node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
NODE_PORT=$(kubectl get svc charles-app-svc -n $NS -o jsonpath='{.spec.ports[0].nodePort}')

# Test with curl
curl http://$NODE_IP:$NODE_PORT

# Or open in browser
echo "http://$NODE_IP:$NODE_PORT"
```

### Port Forward Test

```bash
# Forward to local machine
kubectl port-forward svc/charles-app-svc 8080:80 -n $NS &

# Test
curl http://localhost:8080

# Stop port forward
pkill -f "port-forward"
```

---

## Step 3: Test Self-Healing

### Delete a Pod (Watch Auto-Recovery)

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n $NS -o jsonpath='{.items[0].metadata.name}')

# Delete the pod
kubectl delete pod $POD_NAME -n $NS

# Watch new pod created automatically
kubectl get pods -n $NS -w

# The deployment controller creates a replacement!
```

### Verify Application Stayed Available

```bash
# While deletion happens, test connectivity
curl http://$NODE_IP:$NODE_PORT

# Should still work (other replica handles traffic)
```

---

## Step 4: Test Scaling

### Scale Up

```bash
# Scale to 4 replicas
kubectl scale deployment charles-app --replicas=4 -n $NS

# Watch pods start
kubectl get pods -n $NS -w

# Check distribution
kubectl get pods -n $NS -o wide
```

### Scale Down

```bash
# Scale to 1 replica
kubectl scale deployment charles-app --replicas=1 -n $NS

# Watch pods terminate
kubectl get pods -n $NS -w
```

### Test Service During Scaling

```bash
# Continuous test during scaling
while true; do curl -s http://$NODE_IP:$NODE_PORT > /dev/null && echo "OK" || echo "FAIL"; sleep 1; done

# Press Ctrl+C to stop
# Should see mostly "OK" even during scaling
```

---

## Step 5: Test Rolling Update

### Perform Update

```bash
# Update image
kubectl set image deployment/charles-app nginx=nginx:latest -n $NS

# Watch rollout
kubectl rollout status deployment/charles-app -n $NS
```

### Verify New Pods

```bash
# Check pods (should see new pods)
kubectl get pods -n $NS

# Check image version
kubectl describe deployment charles-app -n $NS | grep Image
```

### Test Rollback

```bash
# Rollback to previous
kubectl rollout undo deployment/charles-app -n $NS

# Watch rollout
kubectl rollout status deployment/charles-app -n $NS
```

---

## Step 6: Monitor Resources

### View Resource Usage

```bash
# Node resources (requires metrics-server)
kubectl top nodes

# Pod resources
kubectl top pods -n $NS
```

### View Events

```bash
# Namespace events
kubectl get events -n $NS --sort-by='.lastTimestamp'

# Cluster-wide events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | head -20
```

### View Logs

```bash
# Pod logs
kubectl logs -l app=charles-app -n $NS --tail=50

# Follow logs
kubectl logs -f -l app=charles-app -n $NS
```

---

## Step 7: Health Check Validation

### Check Readiness/Liveness Probes

If your deployment has probes:

```bash
# Describe pod to see probe status
kubectl describe pod -l app=charles-app -n $NS | grep -A 5 "Liveness\|Readiness"
```

### Test Probe Failure (Optional)

```bash
# Exec into pod and break the app
kubectl exec -it <pod-name> -n $NS -- rm /usr/share/nginx/html/index.html

# Watch what happens (depends on probe config)
kubectl get pods -n $NS -w

# Kubernetes should restart the container
```

---

## ✅ Validation Summary Checklist

### Deployment Health
- [ ] Deployment shows correct replica count
- [ ] All pods are Running
- [ ] Pods distributed across nodes

### Service Connectivity
- [ ] ClusterIP service responds internally
- [ ] NodePort service accessible externally
- [ ] Port forward works

### Self-Healing
- [ ] Deleted pod was auto-replaced
- [ ] Service stayed available during pod deletion

### Scaling
- [ ] Scale up creates new pods
- [ ] Scale down removes pods gracefully
- [ ] Service handles scaling

### Updates
- [ ] Rolling update completed
- [ ] Rollback works

### Monitoring
- [ ] Can view pod logs
- [ ] Can view events
- [ ] Resource usage visible (if metrics-server)

---

## 🚨 Troubleshooting Guide

### Issue: Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n $NS

# Look at Events section for errors

# Common causes:
# - ImagePullBackOff: Wrong image name or no ECR access
# - Pending: Not enough resources on nodes
# - CrashLoopBackOff: App crashes on start
```

### Issue: Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n $NS

# Should show pod IPs
# If empty: selector doesn't match pod labels

# Check security groups (in AWS console)
# - Node security group must allow NodePort range (30000-32767)
```

### Issue: High Restart Count

```bash
# Check why container restarts
kubectl logs <pod-name> --previous -n $NS

# Check probe configuration
kubectl describe pod <pod-name> -n $NS | grep -A 5 "Liveness"
```

---

## 📋 Quick Test Commands

```bash
# Set namespace
export NS=charles-workspace

# Deployment check
kubectl get deployment -n $NS
kubectl get pods -n $NS

# Service check
kubectl get svc -n $NS
kubectl get endpoints -n $NS

# Quick connectivity test
kubectl run test --image=curlimages/curl -it --rm -- curl http://<service-name>.$NS.svc.cluster.local

# Pod health
kubectl describe pod <name> -n $NS
kubectl logs <name> -n $NS

# Events
kubectl get events -n $NS --sort-by='.lastTimestamp'

# Self-healing test
kubectl delete pod <name> -n $NS
kubectl get pods -n $NS -w

# Scale test
kubectl scale deployment <name> --replicas=4 -n $NS
```

---

## 🎓 What You Learned

- ✅ How to verify deployment health
- ✅ How to test service connectivity
- ✅ How Kubernetes self-healing works
- ✅ How scaling affects availability
- ✅ How to monitor and troubleshoot
- ✅ How to validate your applications

---

## 🎉 Congratulations!

You've completed all the hands-on activities!

**You now know how to:**
- ✅ Connect to an EKS cluster
- ✅ Manage namespaces
- ✅ Create and manage node groups
- ✅ Build and push Docker images to ECR
- ✅ Deploy and manage applications
- ✅ Test and validate your deployments

---

## 🧹 Cleanup Your Resources

When you're done:

```bash
# Delete your applications
kubectl delete all --all -n charles-workspace

# Keep or delete your namespace
kubectl delete namespace charles-workspace  # Optional

# Delete any node groups you created
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name charles-nodes \
    --region ap-southeast-1
```

---

## 📚 Next Steps

- Review [PARTICIPANT-CHEATSHEET.md](PARTICIPANT-CHEATSHEET.md) for quick reference
- Check [../REFERENCE/](../REFERENCE/) for detailed command references
- Explore more Kubernetes concepts on your own!

---

## 📖 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [12 Factor App](https://12factor.net/)

