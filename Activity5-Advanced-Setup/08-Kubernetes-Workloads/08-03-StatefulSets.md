# StatefulSets - Stateful Applications

Welcome to the StatefulSets lab! Learn how to deploy and manage stateful applications like databases that require stable identities and persistent storage.

---

## 🎯 Learning Objectives

By the end of this guide, you will:

- ✅ Understand StatefulSets vs Deployments
- ✅ Deploy MySQL with StatefulSet
- ✅ Work with stable network identities
- ✅ Manage persistent storage with StatefulSets
- ✅ Scale stateful applications
- ✅ Understand ordered deployment and updates

---

## ⏱️ Time Estimate

**Total Time: 40-45 minutes**

- Understanding concepts: 10 min
- Deploy StatefulSet: 15 min
- Testing and scaling: 15 min
- Cleanup: 5 min

---

## 📋 Prerequisites

- Cluster running with storage class configured
- kubectl configured
- Understanding of Pods and Deployments
- Completed previous labs on Secrets and ConfigMaps

---

## StatefulSets vs Deployments

### Key Differences

| Feature | Deployment | StatefulSet |
|---------|-----------|-------------|
| **Pod Names** | Random suffix | Ordered index (app-0, app-1) |
| **Network Identity** | No guarantee | Stable DNS per pod |
| **Storage** | Shared or ephemeral | Dedicated PVC per pod |
| **Scaling** | Parallel | Sequential (ordered) |
| **Pod Replacement** | Random name | Same name preserved |
| **Use Case** | Stateless apps | Databases, queues |

### 🏢 Traditional Comparison

**Stateless Application (Deployment):**
```
Multiple identical web servers:
├── web-server-1.example.com (any content)
├── web-server-2.example.com (any content)
└── web-server-3.example.com (any content)
    └── All interchangeable, can be replaced randomly
```

**Stateful Application (StatefulSet):**
```
Database cluster with roles:
├── db-0.example.com (primary - reads/writes)
├── db-1.example.com (replica - reads only)
└── db-2.example.com (replica - reads only)
    └── Each has unique identity, specific role, own data
```

---

## Lab 1: Simple StatefulSet Example

### Step 1: Create a Basic StatefulSet

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
  namespace: default
spec:
  clusterIP: None  # Headless service for StatefulSet
  selector:
    app: nginx-stateful
  ports:
  - port: 80
    name: web
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
  namespace: default
spec:
  serviceName: "nginx-headless"
  replicas: 3
  selector:
    matchLabels:
      app: nginx-stateful
  template:
    metadata:
      labels:
        app: nginx-stateful
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "gp3"  # Use gp3 for AWS EKS
      resources:
        requests:
          storage: 1Gi
EOF
```

**Key Concepts:**
- `serviceName`: Links to headless service for DNS
- `volumeClaimTemplates`: Each pod gets its own PVC
- Pods named sequentially: web-0, web-1, web-2

### Step 2: Watch Ordered Creation

```bash
# Watch pods being created in order
watch -n 1 kubectl get pods -l app=nginx-stateful

# You'll see:
# 1. web-0 created and becomes Ready
# 2. Then web-1 created
# 3. Finally web-2 created
# (Each waits for previous to be Ready)
```

### Step 3: Verify Stable Network Identity

```bash
# Each pod has stable DNS name
for i in 0 1 2; do
  kubectl run -it --rm debug --image=busybox:1.35 --restart=Never -- \
    nslookup web-$i.nginx-headless.default.svc.cluster.local
done

# DNS format: <pod-name>.<service-name>.<namespace>.svc.cluster.local
```

### Step 4: Check Persistent Volumes

```bash
# Each pod has its own PVC
kubectl get pvc

# You'll see:
# www-web-0   Bound   ...   1Gi
# www-web-1   Bound   ...   1Gi
# www-web-2   Bound   ...   1Gi
```

### Step 5: Write Different Data to Each Pod

```bash
# Write unique data to each pod
for i in 0 1 2; do
  kubectl exec web-$i -- sh -c "echo 'This is web-$i' > /usr/share/nginx/html/index.html"
done

# Verify each pod has unique data
for i in 0 1 2; do
  echo "Pod web-$i content:"
  kubectl exec web-$i -- cat /usr/share/nginx/html/index.html
done
```

---

## Lab 2: Deploy MySQL with StatefulSet

### Step 1: Create MySQL Secret

```bash
kubectl create secret generic mysql-secret \
  --from-literal=mysql-root-password=RootPassword123 \
  --from-literal=mysql-password=AppPassword456
```

### Step 2: Create ConfigMap for MySQL Configuration

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
  namespace: default
data:
  my.cnf: |
    [mysqld]
    default-authentication-plugin=mysql_native_password
    max_connections=200
    innodb_buffer_pool_size=256M
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
EOF
```

### Step 3: Deploy MySQL StatefulSet

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: default
  labels:
    app: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
    name: mysql
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: default
spec:
  serviceName: "mysql"
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          value: "testdb"
        - name: MYSQL_USER
          value: "appuser"
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-password
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
        - name: mysql-config
          mountPath: /etc/mysql/conf.d
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mysql
            - -h
            - 127.0.0.1
            - -u
            - root
            - -p\${MYSQL_ROOT_PASSWORD}
            - -e
            - SELECT 1
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 1
      volumes:
      - name: mysql-config
        configMap:
          name: mysql-config
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "gp3"
      resources:
        requests:
          storage: 10Gi
EOF
```

### Step 4: Wait for MySQL to be Ready

```bash
# Watch pod status
kubectl get pods -l app=mysql -w

# Wait for ready condition
kubectl wait --for=condition=ready pod/mysql-0 --timeout=300s

# Check logs
kubectl logs mysql-0 | grep "ready for connections"
```

---

## Lab 3: Working with MySQL Data

### Step 1: Connect to MySQL

```bash
# Connect to MySQL
kubectl exec -it mysql-0 -- mysql -uroot -pRootPassword123

# Run SQL commands:
# CREATE TABLE users (id INT PRIMARY KEY, name VARCHAR(100));
# INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
# SELECT * FROM users;
# EXIT;
```

### Step 2: Test with Application User

```bash
kubectl exec -it mysql-0 -- mysql -uappuser -pAppPassword456 testdb -e "
CREATE TABLE IF NOT EXISTS todos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO todos (title, completed) VALUES 
('Learn Kubernetes', false),
('Deploy StatefulSet', true),
('Master persistent storage', false);

SELECT * FROM todos;
"
```

### Step 3: Verify Data Persistence

```bash
# Delete the pod (simulating failure)
kubectl delete pod mysql-0

# StatefulSet automatically recreates mysql-0 (same name!)
kubectl get pods -l app=mysql -w

# Wait for it to be ready
kubectl wait --for=condition=ready pod/mysql-0 --timeout=300s

# Verify data is still there (from same PVC)
kubectl exec -it mysql-0 -- mysql -uappuser -pAppPassword456 testdb -e "SELECT * FROM todos;"

# Data persists! Same PVC was reattached to new mysql-0 pod
```

---

## Lab 4: Scaling StatefulSets

### Step 1: Check Current PVCs

```bash
# Before scaling
kubectl get pvc -l app=mysql
# Should see: mysql-data-mysql-0
```

### Step 2: Scale to 3 Replicas

```bash
kubectl scale statefulset mysql --replicas=3

# Watch sequential creation
kubectl get pods -l app=mysql -w

# Observe:
# 1. mysql-0 already exists
# 2. mysql-1 created (waits for mysql-0 to be Ready)
# 3. mysql-2 created (waits for mysql-1 to be Ready)
```

### Step 3: Verify Each Pod Gets Its Own Storage

```bash
# Check PVCs
kubectl get pvc -l app=mysql

# You'll see:
# mysql-data-mysql-0   Bound   ...   10Gi
# mysql-data-mysql-1   Bound   ...   10Gi
# mysql-data-mysql-2   Bound   ...   10Gi

# Each pod has its own storage!
```

### Step 4: Verify Stable Network Identity

```bash
# Each pod has stable DNS
for i in 0 1 2; do
  echo "Testing mysql-$i DNS:"
  kubectl run -it --rm test --image=busybox:1.35 --restart=Never -- \
    nslookup mysql-$i.mysql.default.svc.cluster.local
done
```

### Step 5: Connect to Each Instance

```bash
# mysql-0 has data (from earlier labs)
kubectl exec mysql-0 -- mysql -uappuser -pAppPassword456 testdb -e "SELECT COUNT(*) as count FROM todos;"

# mysql-1 and mysql-2 are fresh instances (empty database)
kubectl exec mysql-1 -- mysql -uappuser -pAppPassword456 -e "SHOW DATABASES;"
kubectl exec mysql-2 -- mysql -uappuser -pAppPassword456 -e "SHOW DATABASES;"
```

### 💡 Real MySQL Replication

In production, you'd configure master-slave replication:
```
mysql-0: Primary (read/write)
mysql-1: Replica (read-only, syncs from mysql-0)
mysql-2: Replica (read-only, syncs from mysql-0)
```

This requires additional configuration (init containers, replication scripts).

---

## Lab 5: Ordered Scaling Down

### Step 1: Scale Down

```bash
kubectl scale statefulset mysql --replicas=1

# Watch ordered deletion
kubectl get pods -l app=mysql -w

# Observe:
# 1. mysql-2 deleted first
# 2. mysql-1 deleted second
# 3. mysql-0 remains (reverse order!)
```

### Step 2: Check Storage

```bash
# PVCs are NOT deleted automatically!
kubectl get pvc -l app=mysql

# All 3 PVCs still exist:
# mysql-data-mysql-0   (attached to mysql-0)
# mysql-data-mysql-1   (released, data preserved)
# mysql-data-mysql-2   (released, data preserved)
```

### Step 3: Scale Back Up

```bash
kubectl scale statefulset mysql --replicas=3

# Wait for pods
kubectl wait --for=condition=ready pod/mysql-1 pod/mysql-2 --timeout=300s

# PVCs are reattached!
kubectl get pvc -l app=mysql

# mysql-1 and mysql-2 get their same PVCs back
# Data from before scale-down is still there!
```

---

## Lab 6: Update Strategy

### Rolling Updates

StatefulSets support rolling updates with ordered updates:

```bash
# Update MySQL version
kubectl set image statefulset/mysql mysql=mysql:8.0.35

# Watch ordered update
kubectl get pods -l app=mysql -w

# Observe:
# 1. mysql-2 updated first (highest index)
# 2. mysql-1 updated next
# 3. mysql-0 updated last (lowest index)
# (Reverse order for updates!)
```

### Check Update Status

```bash
kubectl rollout status statefulset/mysql
```

---

## 🏢 Traditional vs Kubernetes StatefulSets

### Traditional Stateful Application

```bash
# Traditional: Manual setup on specific servers
db-primary.example.com:
  - Fixed IP address
  - Specific storage disk (/dev/sdb)
  - Manual failover if down
  
db-replica1.example.com:
  - Fixed IP address  
  - Different storage disk (/dev/sdc)
  - Manual promotion if primary fails

Problems:
❌ Manual server management
❌ Hard to scale
❌ Manual disaster recovery
❌ Complex networking setup
```

### Kubernetes StatefulSet

```yaml
StatefulSet manages:
├── Stable names: mysql-0, mysql-1
├── Stable DNS: mysql-0.mysql.default.svc.cluster.local
├── Persistent storage: Automatic PVC per pod
├── Ordered operations: Sequential deployment/scaling
└── Automatic pod recreation with same identity

Benefits:
✅ Automated management
✅ Easy scaling
✅ Automated recovery
✅ Consistent deployment
```

---

## 💡 Best Practices

### StatefulSet Configuration

```yaml
1. Always use a Headless Service
   clusterIP: None
   # Required for stable network identity

2. Set appropriate resource limits
   resources:
     requests:
       memory: "1Gi"
       cpu: "500m"
     limits:
       memory: "2Gi"
       cpu: "1000m"

3. Use liveness and readiness probes
   livenessProbe:
     # Detect if pod is dead
   readinessProbe:
     # Detect if pod is ready for traffic

4. Plan storage carefully
   # Request adequate size (can't easily shrink)
   # Use appropriate storage class
   # Consider backup strategy
```

### Storage Best Practices

```yaml
1. Use dynamic provisioning
   storageClassName: "gp3"  # Fast, cost-effective

2. Right-size storage
   storage: 20Gi  # Plan for growth

3. Enable volume expansion
   # StorageClass should allow expansion

4. Backup regularly
   # Use VolumeSnapshots
   # Export to S3
   # Test restore procedures
```

---

## 🔍 Troubleshooting

### Pod Won't Start

```bash
# Check pod events
kubectl describe pod mysql-0

# Common issues:
# - Insufficient resources
# - Storage not available
# - Image pull errors
# - Previous pod not Ready
```

### PVC Not Binding

```bash
# Check PVC status
kubectl describe pvc mysql-data-mysql-0

# Check storage class
kubectl get storageclass

# Verify EBS CSI driver (for EKS)
kubectl get pods -n kube-system | grep ebs-csi
```

### Can't Delete StatefulSet

```bash
# Delete with cascade
kubectl delete statefulset mysql --cascade=foreground

# If stuck, delete without waiting
kubectl delete statefulset mysql --cascade=orphan

# Then manually delete pods
kubectl delete pod mysql-0 mysql-1 mysql-2
```

### Delete PVC Stuck

```bash
# Check if pod is using it
kubectl describe pvc <pvc-name>

# Force delete if necessary (caution: data loss!)
kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers":null}}'
kubectl delete pvc <pvc-name>
```

---

## 🧹 Cleanup

### Delete StatefulSet (Keep Data)

```bash
# Delete StatefulSet but keep PVCs
kubectl delete statefulset web mysql
kubectl delete service nginx-headless mysql

# PVCs remain (data preserved)
kubectl get pvc
```

### Delete Everything (Including Data)

```bash
# Delete StatefulSets
kubectl delete statefulset web mysql

# Delete Services
kubectl delete service nginx-headless mysql

# Delete PVCs (THIS DELETES DATA!)
kubectl delete pvc --all

# Delete ConfigMaps and Secrets
kubectl delete configmap mysql-config
kubectl delete secret mysql-secret
```

---

## 📊 When to Use StatefulSets

### Use StatefulSets For:

```
✅ Databases (MySQL, PostgreSQL, MongoDB)
✅ Message queues (Kafka, RabbitMQ)
✅ Distributed systems (Elasticsearch, Cassandra)
✅ Applications requiring:
   - Stable network identity
   - Persistent storage per instance
   - Ordered deployment/scaling
   - Graceful shutdown order
```

### Use Deployments For:

```
✅ Web applications
✅ REST APIs
✅ Stateless microservices
✅ Frontend applications
✅ Worker processes (no state)
```

---

## 📚 Additional Resources

- [StatefulSets Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Run a Replicated Stateful Application](https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/)
- [MySQL on Kubernetes Guide](https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/)

---

## ✅ Knowledge Check

You should now be able to:

- [ ] Explain differences between StatefulSets and Deployments
- [ ] Deploy stateful applications with persistent storage
- [ ] Understand stable network identities
- [ ] Scale StatefulSets safely
- [ ] Manage persistent volumes with StatefulSets
- [ ] Troubleshoot common issues

---

## 🚀 What's Next?

**Continue to:** [08-04-PersistentVolumes.md](08-04-PersistentVolumes.md) for a deep dive into Kubernetes storage.

---

**Fantastic work!** You now understand how to run stateful applications in Kubernetes! 💾

