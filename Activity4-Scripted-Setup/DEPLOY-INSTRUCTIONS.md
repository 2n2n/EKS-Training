# Deployment Instructions for Todo App on thon-eks-cluster

## Prerequisites

- ✅ EKS cluster `thon-eks-cluster` is running
- ✅ kubectl configured to access the cluster
- ✅ Docker installed and running
- ✅ AWS CLI configured with ECR access
- ✅ ECR repositories created for backend and frontend

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                    User's Browser                        │
│                          │                               │
│                    Access via:                           │
│                http://NODE_IP:30080                      │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                 Frontend Service (NodePort)              │
│                    Port: 30080                           │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│              Frontend Pods (2 replicas)                  │
│              - nginx:alpine                              │
│              - Port: 8080                                │
│              - Proxies /api → backend-service            │
└──────────────────────────────────────────────────────────┘
                           │
                    /api/* requests
                           ▼
┌──────────────────────────────────────────────────────────┐
│              Backend Service (ClusterIP)                 │
│              - Internal only                             │
│              - Port: 3000                                │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│              Backend Pods (2 replicas)                   │
│              - Node.js/Express                           │
│              - Port: 3000                                │
│              - Endpoints:                                │
│                • GET  /api/todos                         │
│                • POST /api/todos                         │
│                • PUT  /api/todos/:id                     │
│                • DELETE /api/todos/:id                   │
│                • GET /health                             │
└──────────────────────────────────────────────────────────┘
```

## Step 1: Verify Cluster Connection

```bash
# Check cluster connection
kubectl cluster-info

# Expected output should show thon-eks-cluster
# Kubernetes control plane is running at https://...

# Check nodes
kubectl get nodes

# Expected: 2 nodes in Ready state
```

## Step 2: Build and Push Docker Images to ECR

### Backend Image

```bash
# Navigate to backend directory
cd /EKS-Training/sample-app/backend

# Login to ECR (replace with your region and account ID)
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.ap-southeast-1.amazonaws.com

# Build backend image
docker build -t todo-backend:latest .

# Tag for ECR (YOU WILL PROVIDE THIS)
docker tag todo-backend:latest <ECR_URI_BACKEND>

# Push to ECR
docker push <ECR_URI_BACKEND>
```

### Frontend Image

```bash
# Navigate to frontend directory
cd /EKS-Training/sample-app/frontend

# Build frontend image
docker build -t todo-frontend:latest .

# Tag for ECR (YOU WILL PROVIDE THIS)
docker tag todo-frontend:latest <ECR_URI_FRONTEND>

# Push to ECR
docker push <ECR_URI_FRONTEND>
```

## Step 3: Update Kubernetes Manifests with ECR URIs

You need to replace the placeholders in the manifest files with your actual ECR URIs.

### Backend Deployment

Edit: `/EKS-Training/Activity4-Scripted-Setup/app-manifests/backend-deployment.yaml`

Find and replace:

```yaml
image: <ECR_URI_BACKEND>
```

With your backend ECR URI, for example:

```yaml
image: 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/todo-backend:latest
```

### Frontend Deployment

Edit: `/EKS-Training/Activity4-Scripted-Setup/app-manifests/frontend-deployment.yaml`

Find and replace:

```yaml
image: <ECR_URI_FRONTEND>
```

With your frontend ECR URI, for example:

```yaml
image: 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/todo-frontend:latest
```

## Step 4: Deploy Application to Kubernetes

```bash
# Navigate to app-manifests directory
cd /EKS-Training/Activity4-Scripted-Setup/app-manifests

# Apply all manifests in order
kubectl apply -f namespace.yaml
kubectl apply -f nginx-config.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# Or apply all at once
kubectl apply -f .
```

## Step 5: Verify Deployment

### Check Namespace

```bash
kubectl get namespace todo-app
```

### Check ConfigMap

```bash
kubectl get configmap -n todo-app
kubectl describe configmap nginx-config -n todo-app
```

### Check Deployments

```bash
kubectl get deployments -n todo-app

# Expected output:
# NAME       READY   UP-TO-DATE   AVAILABLE   AGE
# backend    2/2     2            2           1m
# frontend   2/2     2            2           1m
```

### Check Pods

```bash
kubectl get pods -n todo-app

# Expected: 4 pods total (2 backend + 2 frontend), all Running
```

### Check Services

```bash
kubectl get services -n todo-app

# Expected output:
# NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# backend-service    ClusterIP   10.100.x.x      <none>        3000/TCP       1m
# frontend-service   NodePort    10.100.x.x      <none>        80:30080/TCP   1m
```

### Check Pod Logs

Backend logs:

```bash
kubectl logs -n todo-app -l app=backend --tail=50
```

Frontend logs:

```bash
kubectl logs -n todo-app -l app=frontend --tail=50
```

## Step 6: Access the Application

### Get Node External IP

```bash
kubectl get nodes -o wide

# Look for EXTERNAL-IP column
# If using EC2 instances, you may need to use the PUBLIC IP
```

### Access Application

Open in your browser:

```
http://<NODE_EXTERNAL_IP>:30080
```

### Test Backend Health Directly

```bash
# Port-forward to test backend
kubectl port-forward -n todo-app svc/backend-service 3000:3000

# In another terminal:
curl http://localhost:3000/health
curl http://localhost:3000/api/todos
```

## Step 7: Verify Microservices Communication

### Check Frontend Can Reach Backend

```bash
# Get a frontend pod name
FRONTEND_POD=$(kubectl get pods -n todo-app -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Test from within frontend pod
kubectl exec -n todo-app $FRONTEND_POD -- wget -qO- http://backend-service:3000/health
```

Expected output:

```json
{ "status": "healthy", "service": "backend", "timestamp": "..." }
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n todo-app

# Describe pod to see events
kubectl describe pod <pod-name> -n todo-app

# Check logs
kubectl logs <pod-name> -n todo-app
```

### Image Pull Errors

```bash
# Common issues:
# 1. ECR URI incorrect
# 2. No permission to pull from ECR
# 3. Image doesn't exist in ECR

# Verify ECR images exist
aws ecr describe-images --repository-name todo-backend --region ap-southeast-1
aws ecr describe-images --repository-name todo-frontend --region ap-southeast-1
```

### Service Not Accessible

```bash
# Check security groups on EC2 nodes
# Ensure port 30080 is open for NodePort access

# Check if pods are ready
kubectl get pods -n todo-app

# Check service endpoints
kubectl get endpoints -n todo-app
```

### Frontend Can't Reach Backend

```bash
# Check backend service is running
kubectl get svc -n todo-app backend-service

# Check DNS resolution from frontend pod
FRONTEND_POD=$(kubectl get pods -n todo-app -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n todo-app $FRONTEND_POD -- nslookup backend-service

# Check nginx configuration
kubectl exec -n todo-app $FRONTEND_POD -- cat /etc/nginx/conf.d/default.conf
```

## Key Changes Made

1. **Fixed Port Mismatch**: Frontend Dockerfile uses port 8080, updated manifests accordingly
2. **Added Nginx Proxy**: Created ConfigMap to proxy `/api/*` requests to backend service
3. **Updated Frontend Code**: Changed BACKEND_URL to use relative paths
4. **Added Health Checks**: Both services have proper health check endpoints
5. **ECR Integration**: Manifests ready for your ECR URIs

## File Structure

```
Activity4-Scripted-Setup/
└── app-manifests/
    ├── namespace.yaml           # Creates todo-app namespace
    ├── nginx-config.yaml        # NEW: Nginx proxy configuration
    ├── backend-deployment.yaml  # Backend deployment + service
    └── frontend-deployment.yaml # Frontend deployment + service

sample-app/
├── backend/
│   ├── Dockerfile              # Backend Docker image
│   ├── server.js              # Express API server
│   └── package.json           # Node dependencies
└── frontend/
    ├── Dockerfile             # Frontend Docker image
    ├── src/index.html         # UPDATED: Uses relative URLs
    └── nginx.conf             # Original nginx config (overridden by ConfigMap)
```

## Testing Checklist

- [ ] Cluster connection verified
- [ ] Backend image built and pushed to ECR
- [ ] Frontend image built and pushed to ECR
- [ ] Manifests updated with ECR URIs
- [ ] All manifests applied successfully
- [ ] All 4 pods are Running (2 backend + 2 frontend)
- [ ] Both services are created
- [ ] Application accessible at http://NODE_IP:30080
- [ ] Can add todos via the UI
- [ ] Can mark todos as complete
- [ ] Can delete todos
- [ ] Backend health check works
- [ ] No errors in pod logs

## Cleanup (When Done)

```bash
# Delete all resources in the namespace
kubectl delete namespace todo-app

# Verify deletion
kubectl get all -n todo-app
# Should return: No resources found
```

## Next Steps

After confirming the app is working:

1. ✅ Verify all functionality
2. 📝 Documentation will be created
3. 🎓 Review microservices architecture benefits
4. 🚀 Compare with Activity 3 monolith approach

---

**Questions or Issues?** Check the troubleshooting section or review pod logs for errors.
