# Kubernetes Concepts: Container Orchestration

**Estimated Reading Time: 45 minutes**

---

## 🎯 What is Kubernetes?

**Kubernetes** (K8s) is a container orchestration platform. It manages Docker containers across multiple servers.

**Simple analogy:** If Docker is like shipping containers, Kubernetes is the port authority that manages thousands of containers across many ships and docks.

---

## 🤔 Why Do You Need Kubernetes?

### Docker Alone: Good for One Server

```bash
# You can manage containers on one server:
docker run -d app1
docker run -d app2
docker run -d app3

# But what about:
# - 10 servers with 100 containers?
# - Auto-restart if container crashes?
# - Load balancing across containers?
# - Rolling updates with zero downtime?
# - Auto-scaling based on load?

Docker doesn't solve these!
```

### Kubernetes: Manages Many Servers

```
Kubernetes Cluster:
├── Server 1
│   ├── Container A
│   └── Container B
├── Server 2
│   ├── Container C
│   └── Container D
└── Server 3
    ├── Container E
    └── Container F

Kubernetes:
✅ Decides which server runs which container
✅ Restarts crashed containers
✅ Load balances traffic
✅ Rolls out updates
✅ Scales automatically
```

---

## 🏗️ Kubernetes Architecture

### High-Level View

```
┌─────────────────────────────────────────────────┐
│            Kubernetes Cluster                    │
│                                                  │
│  ┌───────────────────────────────────────────┐  │
│  │     Control Plane (The Brain)             │  │
│  │  - API Server (talks to you)              │  │
│  │  - Scheduler (decides placement)          │  │
│  │  - Controller Manager (maintains state)   │  │
│  │  - etcd (database)                        │  │
│  └───────────────────────────────────────────┘  │
│                     │                            │
│                     ▼                            │
│  ┌──────────────────────────────────────────┐   │
│  │        Worker Nodes (The Muscle)         │   │
│  │                                          │   │
│  │  ┌────────┐  ┌────────┐  ┌────────┐    │   │
│  │  │ Node 1 │  │ Node 2 │  │ Node 3 │    │   │
│  │  │        │  │        │  │        │    │   │
│  │  │ Pods   │  │ Pods   │  │ Pods   │    │   │
│  │  └────────┘  └────────┘  └────────┘    │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

**Traditional equivalent:**

```
Traditional:              Kubernetes:
Your commands       →     Control Plane
Your servers        →     Worker Nodes
Your applications   →     Pods
```

---

## 🧩 Core Kubernetes Objects

### 1. Pod - The Smallest Unit

**What is it?**
A Pod is a wrapper around one or more containers.

```
Pod = 1 or more containers that run together

┌─────────────────────┐
│       Pod           │
│                     │
│  ┌──────────────┐  │
│  │  Container 1 │  │  ← Usually just one
│  └──────────────┘  │
│                     │
│  (Sometimes more)   │
│  ┌──────────────┐  │
│  │  Container 2 │  │  ← Helper/sidecar
│  └──────────────┘  │
└─────────────────────┘

Pod gets:
- Unique IP address
- Shared storage
- Shared network
```

**Traditional equivalent:**

```
Pod ≈ Application instance

Traditional:          Kubernetes:
Node.js process  →    Pod with Node.js container
nginx process    →    Pod with nginx container
```

**Example Pod YAML:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp
    image: myapp:v1
    ports:
    - containerPort: 3000
```

**Life of a Pod:**

```
1. Pending → Scheduled to a node
2. Running → Container(s) running
3. Succeeded/Failed → Completed
4. Pods are disposable!

Pod crashes? Create new one.
Pod's node fails? Create new one elsewhere.
```

### 2. Deployment - Manages Pods

**What is it?**
Deployment manages multiple identical Pods and handles updates.

```
Deployment: "I want 3 replicas of myapp:v1"

                Deployment
                    │
        ┌───────────┼───────────┐
        │           │           │
     Pod 1       Pod 2       Pod 3
    myapp:v1    myapp:v1    myapp:v1

If Pod 2 crashes:
- Kubernetes detects
- Creates new Pod 2
- Always maintains 3 replicas
```

**Traditional equivalent:**

```
Traditional:                 Kubernetes Deployment:
pm2 start server.js -i 3  → 3 Pod replicas
pm2 restart               → Rolling update
Auto-restart on crash     → Self-healing pods
```

**Example Deployment YAML:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
spec:
  replicas: 3  # "I want 3 copies"
  selector:
    matchLabels:
      app: myapp
  template:  # Pod template
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:v1
        ports:
        - containerPort: 3000
```

**Rolling Updates:**

```
Current: 3 Pods running v1
Update to: v2

Kubernetes automatically:
1. Creates 1 Pod with v2
2. Waits for it to be ready
3. Deletes 1 Pod with v1
4. Repeat until all Pods are v2

┌─────────┐   ┌─────────┐   ┌─────────┐
│ v1      │   │ v1      │   │ v1      │
└─────────┘   └─────────┘   └─────────┘

┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│ v1      │   │ v1      │   │ v1      │   │ v2      │ ← New
└─────────┘   └─────────┘   └─────────┘   └─────────┘

┌─────────┐   ┌─────────┐   ┌─────────┐
│ v1      │   │ v1      │   │ v2      │ ← Old removed
└─────────┘   └─────────┘   └─────────┘

Continue until all v2...
Zero downtime! ✅
```

### 3. Service - Networking & Load Balancing

**What is it?**
Service provides a stable way to access Pods (which have changing IPs).

**The Problem:**

```
Pods are ephemeral:
- Pod 1: IP 10.0.1.5  ← Crashes
- Pod 1 (new): IP 10.0.1.8  ← Different IP!

How do other Pods find your app?
IPs keep changing!
```

**The Solution: Service**

```
Service: Stable IP/DNS name
    │
    ├─→ Routes to Pod 1 (10.0.1.5)
    ├─→ Routes to Pod 2 (10.0.1.7)
    └─→ Routes to Pod 3 (10.0.1.9)

Access "myapp-service" → Load balanced to any Pod
Service IP never changes!
```

**Traditional equivalent:**

```
Traditional:               Kubernetes Service:
nginx load balancer   →    Service with ClusterIP
HAProxy               →    Service
Internal DNS          →    Service discovery
```

**Service Types:**

```yaml
# 1. ClusterIP (default) - Internal only
kind: Service
spec:
  type: ClusterIP  # Only accessible inside cluster
  ports:
  - port: 80
    targetPort: 3000

# 2. NodePort - External access via node IP
kind: Service
spec:
  type: NodePort  # Accessible from outside
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30080  # Access via node-ip:30080

# 3. LoadBalancer - Cloud load balancer
kind: Service
spec:
  type: LoadBalancer  # Creates AWS/GCP load balancer
  ports:
  - port: 80
    targetPort: 3000
```

**Example Service YAML:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp  # Routes to Pods with this label
  ports:
  - port: 80        # Service port
    targetPort: 3000  # Container port
  type: NodePort
```

### 4. ConfigMap - Configuration Data

**What is it?**
Store configuration data (non-sensitive) separately from code.

```
Without ConfigMap:
- Hard-code values in container
- Rebuild image for every config change
- Different images for dev/staging/prod

With ConfigMap:
- Store config in Kubernetes
- Same image everywhere
- Change config without rebuilding
```

**Traditional equivalent:**

```
Traditional:           Kubernetes:
.env file         →    ConfigMap
config.json       →    ConfigMap
Environment vars  →    ConfigMap
```

**Example ConfigMap:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: "postgres.default.svc.cluster.local"
  api_url: "https://api.example.com"
  log_level: "info"
```

**Using in Pod:**

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: myapp
    image: myapp:v1
    envFrom:
    - configMapRef:
        name: app-config
    # Container sees DATABASE_HOST, API_URL, LOG_LEVEL
```

### 5. Secret - Sensitive Data

**What is it?**
Like ConfigMap but for sensitive data (passwords, tokens).

```
ConfigMap: Public config (URLs, settings)
Secret: Private config (passwords, API keys)
```

**Example Secret:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db_password: bXlwYXNzd29yZA==  # base64 encoded
  api_key: c2VjcmV0a2V5MTIz
```

**Using in Pod:**

```yaml
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: myapp
    image: myapp:v1
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: db_password
```

### 6. Namespace - Logical Separation

**What is it?**
Namespaces separate resources within same cluster.

```
Cluster
├── Namespace: development
│   ├── Deployment: frontend
│   └── Service: backend
├── Namespace: staging
│   ├── Deployment: frontend
│   └── Service: backend
└── Namespace: production
    ├── Deployment: frontend
    └── Service: backend

Same names, different namespaces
Isolated from each other
```

**Traditional equivalent:**

```
Traditional:          Kubernetes:
Separate servers  →   Namespaces
/var/www/dev      →   dev namespace
/var/www/prod     →   prod namespace
```

**Default Namespaces:**

```bash
# Kubernetes creates these:
default          # Your stuff goes here by default
kube-system      # Kubernetes system components
kube-public      # Public resources
kube-node-lease  # Node heartbeat data
```

---

## 🎭 How It All Works Together

### Complete Example: Todo App

```yaml
# 1. ConfigMap - Configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-config
data:
  api_url: "http://backend-service:3000"

---
# 2. Secret - Sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: todo-secrets
type: Opaque
data:
  jwt_secret: c2VjcmV0MTIz

---
# 3. Deployment - Backend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: todo-backend:v1
        ports:
        - containerPort: 3000
        envFrom:
        - secretRef:
            name: todo-secrets

---
# 4. Service - Backend
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP  # Internal only

---
# 5. Deployment - Frontend
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: todo-frontend:v1
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: todo-config

---
# 6. Service - Frontend
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort  # External access
```

**What happens:**

```
1. User visits: http://node-ip:30080
   ↓
2. NodePort service routes to frontend Pod
   ↓
3. Frontend calls backend via "backend-service:3000"
   ↓
4. Service load-balances to backend Pod
   ↓
5. Backend processes request
   ↓
6. Response flows back to user
```

---

## 🔄 Kubernetes Control Loop

### Declarative vs Imperative

**Imperative (Traditional):**

```bash
# You tell system HOW to do things:
ssh server1
docker run myapp
ssh server2
docker run myapp
# Step by step commands
```

**Declarative (Kubernetes):**

```yaml
# You tell system WHAT you want:
spec:
  replicas: 3
# Kubernetes figures out HOW
```

### The Control Loop

```
┌─────────────────────────────────────┐
│  1. You declare desired state:     │
│     "I want 3 Pods running"         │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  2. Kubernetes checks actual state: │
│     "Currently 2 Pods running"      │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  3. Kubernetes reconciles:          │
│     "I need to create 1 more Pod"   │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  4. Kubernetes creates Pod          │
│     "Now 3 Pods running ✅"          │
└─────────────────────────────────────┘
              │
              ▼
        (Continuously monitors)
```

**This happens automatically, continuously, forever!**

---

## 🛠️ kubectl - The Kubernetes CLI

### Basic Commands

```bash
# View resources
kubectl get pods               # List pods
kubectl get deployments        # List deployments
kubectl get services           # List services
kubectl get all                # List everything

# Describe (detailed info)
kubectl describe pod myapp-pod
kubectl describe deployment myapp

# Create resources
kubectl create -f deployment.yaml
kubectl apply -f deployment.yaml  # Preferred (updates existing)

# Delete resources
kubectl delete pod myapp-pod
kubectl delete deployment myapp

# View logs
kubectl logs myapp-pod
kubectl logs -f myapp-pod  # Follow logs

# Execute commands
kubectl exec -it myapp-pod -- bash  # Like docker exec

# Scale deployment
kubectl scale deployment myapp --replicas=5
```

**Traditional equivalent:**

```
Traditional:          kubectl:
ssh commands     →    kubectl exec
service logs     →    kubectl logs
ps aux           →    kubectl get pods
service restart  →    kubectl rollout restart
```

---

## 📊 Kubernetes vs Traditional Comparison

| Task | Traditional | Kubernetes |
|------|-------------|------------|
| **Deploy app** | SSH + manual steps | `kubectl apply` |
| **Scale up** | Set up new servers | `kubectl scale` |
| **Update app** | SSH to each server | Rolling update |
| **Restart crashed app** | Manual | Automatic |
| **Load balance** | Configure nginx/HAProxy | Built-in Service |
| **Configuration** | Edit files on servers | ConfigMap/Secret |
| **Service discovery** | Manual DNS/hosts file | Automatic |
| **Health checks** | External monitoring | Built-in liveness probes |
| **Rollback** | Manual restore | `kubectl rollout undo` |

---

## ✅ Key Takeaways

### Kubernetes Provides:
- ✅ Container orchestration across many servers
- ✅ Self-healing (auto-restart)
- ✅ Auto-scaling
- ✅ Load balancing
- ✅ Rolling updates
- ✅ Service discovery
- ✅ Configuration management

### Core Concepts:
- **Pod**: Smallest unit (1+ containers)
- **Deployment**: Manages Pods, handles updates
- **Service**: Stable networking, load balancing
- **ConfigMap**: Non-sensitive configuration
- **Secret**: Sensitive data
- **Namespace**: Logical separation

### Philosophy:
- **Declarative**: Describe what you want
- **Self-healing**: Maintains desired state
- **Immutable**: Replace, don't modify
- **Scalable**: Designed for many servers

---

## 🚀 Next Steps

You now understand core Kubernetes concepts!

**Next:** [04-AWS-Fundamentals.md](04-AWS-Fundamentals.md) - Learn the AWS services we'll use for EKS!

---

**Remember:** Kubernetes automates what you've been doing manually. Same concepts, automated execution! 🤖

