# Activity 5: Deploy Applications

**For:** Workshop Participants  
**Time:** 40 minutes  
**Prerequisites:** Completed [04-ECR-IMAGE-WORKFLOW.md](04-ECR-IMAGE-WORKFLOW.md)

Learn how to deploy, manage, and expose applications in Kubernetes.

---

## 🎯 What You'll Learn

- Create Kubernetes Deployments
- Manage pods and replicas
- Create Services (ClusterIP, NodePort)
- Scale applications
- Perform rolling updates
- View logs and debug pods

---

## Step 1: Deploy Using YAML (Recommended)

### Create Deployment YAML

Create a file `charles-app.yaml` (use YOUR name!):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: charles-app
  namespace: charles-workspace
  labels:
    app: charles-app
    owner: charles
spec:
  replicas: 2
  selector:
    matchLabels:
      app: charles-app
  template:
    metadata:
      labels:
        app: charles-app
        owner: charles
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: charles-app-svc
  namespace: charles-workspace
spec:
  type: NodePort
  selector:
    app: charles-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

### Apply the Deployment

```bash
# Create namespace if not exists
kubectl create namespace charles-workspace 2>/dev/null || true

# Apply configuration
kubectl apply -f charles-app.yaml

# Expected output:
# deployment.apps/charles-app created
# service/charles-app-svc created
```

### Verify Deployment

```bash
# Check deployment status
kubectl get deployment charles-app -n charles-workspace

# Check pods
kubectl get pods -n charles-workspace

# Check service
kubectl get svc charles-app-svc -n charles-workspace
```

---

## Step 2: Deploy Using kubectl Commands

### Create Deployment Imperatively

```bash
# Create deployment (quick way)
kubectl create deployment charles-quick \
    --image=nginx:alpine \
    --replicas=2 \
    -n charles-workspace

# Expose as service
kubectl expose deployment charles-quick \
    --type=NodePort \
    --port=80 \
    -n charles-workspace
```

### View Created Resources

```bash
# See everything
kubectl get all -n charles-workspace
```

---

## Step 3: Access Your Application

### Get NodePort and Node IP

```bash
# Get NodePort
kubectl get svc charles-app-svc -n charles-workspace -o jsonpath='{.spec.ports[0].nodePort}'

# Get Node External IP
kubectl get nodes -o wide | awk '{print $7}' | tail -n1
```

### Access Application

```bash
# Construct URL
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
NODE_PORT=$(kubectl get svc charles-app-svc -n charles-workspace -o jsonpath='{.spec.ports[0].nodePort}')

echo "Access your app at: http://$NODE_IP:$NODE_PORT"

# Test with curl
curl http://$NODE_IP:$NODE_PORT
```

### Alternative: Port Forward (Local Access)

```bash
# Forward local port to service
kubectl port-forward svc/charles-app-svc 8080:80 -n charles-workspace

# Access at http://localhost:8080
# Press Ctrl+C to stop
```

---

## Step 4: Scale Your Deployment

### Scale Replicas

```bash
# Scale up to 4 replicas
kubectl scale deployment charles-app --replicas=4 -n charles-workspace

# Watch pods scale up
kubectl get pods -n charles-workspace -w

# Scale down to 2
kubectl scale deployment charles-app --replicas=2 -n charles-workspace
```

### Edit Deployment Directly

```bash
# Edit deployment (opens in editor)
kubectl edit deployment charles-app -n charles-workspace

# Change replicas field, save and exit
```

---

## Step 5: Update Your Application

### Rolling Update

```bash
# Update image (triggers rolling update)
kubectl set image deployment/charles-app \
    nginx=nginx:latest \
    -n charles-workspace

# Watch rollout
kubectl rollout status deployment/charles-app -n charles-workspace
```

### View Rollout History

```bash
# See rollout history
kubectl rollout history deployment/charles-app -n charles-workspace

# See specific revision
kubectl rollout history deployment/charles-app --revision=1 -n charles-workspace
```

### Rollback If Needed

```bash
# Rollback to previous version
kubectl rollout undo deployment/charles-app -n charles-workspace

# Rollback to specific revision
kubectl rollout undo deployment/charles-app --to-revision=1 -n charles-workspace
```

---

## Step 6: View Logs and Debug

### View Pod Logs

```bash
# Get pod name
kubectl get pods -n charles-workspace

# View logs
kubectl logs <pod-name> -n charles-workspace

# Follow logs (streaming)
kubectl logs -f <pod-name> -n charles-workspace

# View previous container logs (if crashed)
kubectl logs <pod-name> --previous -n charles-workspace

# Logs from all pods with label
kubectl logs -l app=charles-app -n charles-workspace
```

### Execute Commands in Pod

```bash
# Get shell access
kubectl exec -it <pod-name> -n charles-workspace -- /bin/sh

# Run single command
kubectl exec <pod-name> -n charles-workspace -- ls /usr/share/nginx/html

# Exit shell with: exit
```

### Describe Resources

```bash
# Detailed pod info
kubectl describe pod <pod-name> -n charles-workspace

# Detailed deployment info
kubectl describe deployment charles-app -n charles-workspace

# View events
kubectl get events -n charles-workspace --sort-by='.lastTimestamp'
```

---

## Step 7: Delete Resources

### Delete Specific Resources

```bash
# Delete deployment
kubectl delete deployment charles-app -n charles-workspace

# Delete service
kubectl delete svc charles-app-svc -n charles-workspace

# Delete using YAML file
kubectl delete -f charles-app.yaml
```

### Delete All in Namespace

```bash
# Delete all resources in YOUR namespace
kubectl delete all --all -n charles-workspace

# ⚠️ This deletes EVERYTHING in the namespace!
```

---

## 📝 Complete Deployment Example

### Multi-Container Application

```yaml
# Save as charles-fullapp.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: charles-fullapp
  namespace: charles-workspace
spec:
  replicas: 2
  selector:
    matchLabels:
      app: charles-fullapp
  template:
    metadata:
      labels:
        app: charles-fullapp
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: charles-fullapp-svc
  namespace: charles-workspace
spec:
  type: NodePort
  selector:
    app: charles-fullapp
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30082
```

---

## ✅ Validation Checklist

- [ ] Created deployment using YAML
- [ ] Verified pods are running
- [ ] Created service and accessed application
- [ ] Scaled deployment up and down
- [ ] Performed rolling update
- [ ] Viewed pod logs
- [ ] Executed commands in pod
- [ ] Cleaned up resources

---

## 📋 Quick Commands Reference

```bash
# CREATE
kubectl apply -f deployment.yaml
kubectl create deployment <name> --image=<image>

# VIEW
kubectl get deployments -n <namespace>
kubectl get pods -n <namespace>
kubectl get svc -n <namespace>
kubectl get all -n <namespace>
kubectl describe deployment <name> -n <namespace>
kubectl describe pod <name> -n <namespace>

# SCALE
kubectl scale deployment <name> --replicas=<n> -n <namespace>

# UPDATE
kubectl set image deployment/<name> <container>=<image> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> -n <namespace>

# LOGS & DEBUG
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
kubectl get events -n <namespace>

# EXPOSE
kubectl expose deployment <name> --type=NodePort --port=80 -n <namespace>
kubectl port-forward svc/<name> 8080:80 -n <namespace>

# DELETE
kubectl delete -f deployment.yaml
kubectl delete deployment <name> -n <namespace>
kubectl delete svc <name> -n <namespace>
kubectl delete all --all -n <namespace>
```

---

## 🎓 What You Learned

- ✅ How to create deployments declaratively and imperatively
- ✅ How to expose applications with services
- ✅ How to scale applications
- ✅ How to perform rolling updates and rollbacks
- ✅ How to view logs and debug pods
- ✅ How to clean up resources

---

## 🚀 Next Activity

Test everything you've built!

**Next:** [06-TESTING-AND-VALIDATION.md](06-TESTING-AND-VALIDATION.md) - Test and validate your deployments

---

## 📚 Additional Resources

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

