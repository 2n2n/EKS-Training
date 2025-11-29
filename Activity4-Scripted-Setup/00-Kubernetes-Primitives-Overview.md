# Kubernetes Primitives Overview

Welcome to the Kubernetes Primitives overview! Before diving into the scripted setup, let's understand the different types of workloads and resources Kubernetes provides.

---

## 🎯 Learning Objectives

By the end of this guide, you will understand:

- ✅ Different Kubernetes workload types and when to use them
- ✅ How to manage configuration and secrets
- ✅ Storage abstraction with Persistent Volumes
- ✅ When to use each primitive in production

**Note:** This is a **conceptual overview**. Hands-on labs for these primitives are in Activity 5, Part A.

---

## 📚 Table of Contents

1. [Workload Types Overview](#workload-types-overview)
2. [Jobs and CronJobs](#jobs-and-cronjobs)
3. [Secrets and ConfigMaps](#secrets-and-configmaps)
4. [StatefulSets vs Deployments](#statefulsets-vs-deployments)
5. [Persistent Volumes (PV/PVC)](#persistent-volumes-pvpvc)
6. [DaemonSets](#daemonsets)
7. [When to Use Each Primitive](#when-to-use-each-primitive)

---

## Workload Types Overview

Kubernetes provides different workload types for different use cases:

```
Workload Types:
├── Deployments: Stateless applications (most common)
├── StatefulSets: Stateful applications (databases, etc.)
├── DaemonSets: One pod per node (monitoring, logging)
├── Jobs: Run-to-completion tasks
├── CronJobs: Scheduled tasks
└── ReplicaSets: Low-level (usually managed by Deployments)
```

### 🏢 Traditional Way vs ☁️ Kubernetes Way

**Traditional:**
- Run applications directly on servers
- Use cron for scheduled tasks
- Manage configuration files manually
- Set up databases with manual storage

**Kubernetes:**
- Declare desired state in YAML
- Let Kubernetes manage the actual state
- Automatic restarts and scaling
- Abstracted storage and configuration

---

## Jobs and CronJobs

### What Are Jobs?

**Jobs** run one or more Pods to completion. Once the task finishes successfully, the Job is complete.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: database-backup
spec:
  template:
    spec:
      containers:
      - name: backup
        image: mysql:8.0
        command: ["mysqldump", "-h", "mysql", "-u", "root", "mydb"]
      restartPolicy: OnFailure
```

### 🏢 Traditional Equivalent

```bash
# Traditional: Run a backup script manually or via cron
/usr/local/bin/backup-database.sh

# If it fails, you manually re-run it
```

### ☁️ Kubernetes Job Benefits

```
✅ Automatic retries on failure
✅ Tracks completion status
✅ Can run multiple pods in parallel
✅ Automatic cleanup of old jobs
✅ Logs preserved for debugging
```

### What Are CronJobs?

**CronJobs** run Jobs on a schedule (like traditional cron).

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-backup
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: mysql:8.0
            command: ["mysqldump", "-h", "mysql", "-u", "root", "mydb"]
          restartPolicy: OnFailure
```

### Use Cases

**Jobs:**
- Database migrations
- Data processing tasks
- One-time setup scripts
- Batch processing
- Video encoding
- Report generation

**CronJobs:**
- Scheduled backups
- Data cleanup tasks
- Report generation (daily/weekly)
- Certificate renewal checks
- Health checks and audits

### 💡 Key Concepts

```yaml
Job Configuration:
├── completions: Number of successful completions needed
├── parallelism: Number of pods to run in parallel
├── backoffLimit: Number of retries before marking as failed
└── ttlSecondsAfterFinished: Auto-cleanup after completion

CronJob Configuration:
├── schedule: Cron expression (same as Linux cron)
├── concurrencyPolicy: Allow/Forbid/Replace concurrent runs
├── successfulJobsHistoryLimit: Keep last N successful jobs
└── failedJobsHistoryLimit: Keep last N failed jobs
```

---

## Secrets and ConfigMaps

### What Are ConfigMaps?

**ConfigMaps** store non-sensitive configuration data as key-value pairs.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  DATABASE_HOST: "mysql.default.svc.cluster.local"
  MAX_CONNECTIONS: "100"
```

### What Are Secrets?

**Secrets** store sensitive data like passwords, tokens, and keys (base64 encoded).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQxMjM=  # base64 encoded
  API_KEY: YWJjZGVmZ2hpamtsbW5vcA==
```

### 🏢 Traditional Way

```bash
# Traditional: Configuration in files or environment
# /etc/myapp/config.ini
DB_HOST=localhost
DB_USER=root
DB_PASS=password123

# Or environment variables in systemd/init scripts
Environment="DB_PASSWORD=password123"
```

### ☁️ Kubernetes Way

```yaml
# Inject as environment variables
env:
  - name: DATABASE_HOST
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: DATABASE_HOST
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: DB_PASSWORD

# Or mount as files
volumeMounts:
  - name: config
    mountPath: /etc/config
volumes:
  - name: config
    configMap:
      name: app-config
```

### 💡 Best Practices

**ConfigMaps:**
- ✅ Use for non-sensitive configuration
- ✅ Environment-specific settings
- ✅ Feature flags
- ✅ Application parameters

**Secrets:**
- ✅ Use for passwords and tokens
- ✅ Enable encryption at rest (AWS KMS integration)
- ✅ Use RBAC to limit access
- ⚠️ Remember: base64 is NOT encryption!

### ConfigMap vs Secret vs Environment Variables

```
ConfigMap:
├── Pros: Easy updates, centralized config, can be shared
├── Cons: Not encrypted by default
└── Use: Application settings, feature flags

Secret:
├── Pros: Can be encrypted, access controlled via RBAC
├── Cons: Still base64 in etcd unless encrypted at rest
└── Use: Passwords, API keys, certificates

Environment Variables (hardcoded):
├── Pros: Simple, no external dependencies
├── Cons: Requires rebuild to change, not secure
└── Use: Default values only, never credentials
```

---

## StatefulSets vs Deployments

### What Are StatefulSets?

**StatefulSets** manage stateful applications that need:
- Stable network identities
- Persistent storage
- Ordered deployment and scaling

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
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
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### Deployments (Review)

**Deployments** manage stateless applications where any pod is interchangeable.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:latest
```

### 🏢 Traditional Comparison

**Stateless (Deployment):**
```
Traditional: Multiple web servers behind load balancer
- server1.example.com
- server2.example.com
- server3.example.com
└── All identical, interchangeable
```

**Stateful (StatefulSet):**
```
Traditional: Database cluster with specific roles
- db-primary.example.com (master)
- db-replica-1.example.com (read replica)
- db-replica-2.example.com (read replica)
└── Each has unique identity and data
```

### Key Differences

| Feature | Deployment | StatefulSet |
|---------|-----------|-------------|
| **Pod Names** | Random (webapp-6d5f4-abc12) | Sequential (mysql-0, mysql-1) |
| **Network Identity** | No stable DNS | Stable DNS per pod |
| **Storage** | Shared or ephemeral | Dedicated PVC per pod |
| **Scaling** | Parallel | Sequential (ordered) |
| **Updates** | Rolling (random order) | Ordered updates |
| **Use Case** | Web apps, APIs | Databases, message queues |

### When to Use Each

**Use Deployments for:**
- ✅ Stateless web applications
- ✅ REST APIs
- ✅ Microservices
- ✅ Frontend applications
- ✅ Worker processes (no state)

**Use StatefulSets for:**
- ✅ Databases (MySQL, PostgreSQL, MongoDB)
- ✅ Message queues (Kafka, RabbitMQ)
- ✅ Distributed systems (Elasticsearch, Cassandra)
- ✅ Anything requiring stable network identity
- ✅ Applications with persistent state

### 💡 StatefulSet Features

```
Pod Identity:
├── mysql-0: Always mysql-0.mysql.default.svc.cluster.local
├── mysql-1: Always mysql-1.mysql.default.svc.cluster.local
└── mysql-2: Always mysql-2.mysql.default.svc.cluster.local

Persistent Storage:
├── mysql-0: Gets PVC data-mysql-0 (always the same PVC)
├── mysql-1: Gets PVC data-mysql-1
└── mysql-2: Gets PVC data-mysql-2

Ordered Operations:
├── Scaling Up: 0 → 1 → 2 (sequential)
├── Scaling Down: 2 → 1 → 0 (reverse order)
└── Updates: Same ordered approach
```

---

## Persistent Volumes (PV/PVC)

### Storage Abstraction

Kubernetes separates storage into three concepts:

```
Storage Abstraction:
├── StorageClass: Defines types of storage available
├── PersistentVolume (PV): Actual storage (admin creates)
└── PersistentVolumeClaim (PVC): Request for storage (user creates)
```

### 🏢 Traditional Storage

```bash
# Traditional: Direct disk management
mkfs.ext4 /dev/sdb1
mount /dev/sdb1 /var/lib/mysql

# In /etc/fstab
/dev/sdb1  /var/lib/mysql  ext4  defaults  0  0
```

### ☁️ Kubernetes Storage

```yaml
# Step 1: StorageClass (often pre-created by cloud provider)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"

---
# Step 2: PersistentVolumeClaim (user requests storage)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-data
spec:
  storageClassName: fast-ssd
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi

---
# Step 3: Use in Pod
apiVersion: v1
kind: Pod
metadata:
  name: mysql
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    volumeMounts:
    - name: data
      mountPath: /var/lib/mysql
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: mysql-data
```

### Access Modes

```yaml
Access Modes:
├── ReadWriteOnce (RWO): One node, read-write
│   └── Use: Databases, single-node apps
├── ReadOnlyMany (ROX): Many nodes, read-only
│   └── Use: Shared configuration, static content
└── ReadWriteMany (RWX): Many nodes, read-write
    └── Use: Shared file systems (requires NFS/EFS)
```

### AWS EBS in EKS

```
EBS Volumes in EKS:
├── Automatically provisioned via CSI driver
├── Support: ReadWriteOnce only (single node)
├── Types: gp3 (recommended), gp2, io1, io2
├── Snapshots: Automatic backups via VolumeSnapshot
└── Cost: ~$0.08/GB/month for gp3
```

### 💡 Volume Lifecycle

```
1. User creates PVC → "Pending"
2. Dynamic provisioner creates PV (e.g., EBS volume)
3. PV binds to PVC → "Bound"
4. Pod uses PVC → Volume mounted
5. Pod deleted → PVC remains (data persists)
6. PVC deleted → PV deleted (by default with "Delete" policy)

Reclaim Policies:
├── Delete: Remove PV when PVC deleted (default)
└── Retain: Keep PV for manual recovery
```

### Ephemeral vs Persistent

**Ephemeral Volumes:**
```yaml
# emptyDir: Temporary storage, deleted with pod
volumes:
- name: cache
  emptyDir: {}
```
Use for: Temporary files, caches, scratch space

**Persistent Volumes:**
```yaml
# PVC: Survives pod deletion
volumes:
- name: data
  persistentVolumeClaim:
    claimName: mysql-data
```
Use for: Databases, user uploads, any important data

---

## DaemonSets

### What Are DaemonSets?

**DaemonSets** ensure a pod runs on every node (or selected nodes).

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      containers:
      - name: node-exporter
        image: prom/node-exporter:latest
        ports:
        - containerPort: 9100
```

### 🏢 Traditional Equivalent

```bash
# Traditional: Install monitoring agent on every server
# On server1, server2, server3, etc.
apt-get install node-exporter
systemctl enable node-exporter
systemctl start node-exporter
```

### ☁️ Kubernetes DaemonSet Benefits

```
✅ Automatically runs on new nodes
✅ Automatically removed from deleted nodes
✅ Centralized management
✅ Version control
✅ Automatic updates
```

### Common Use Cases

**DaemonSets are ideal for:**
- **Monitoring agents**: node-exporter, Datadog agent
- **Log collectors**: Fluentd, Logstash, Filebeat
- **Network plugins**: CNI plugins, kube-proxy
- **Storage**: Ceph, GlusterFS agents
- **Security**: Security scanning, intrusion detection

### 💡 DaemonSet Features

```
Node Selection:
├── nodeSelector: Run only on nodes with specific labels
├── nodeAffinity: Advanced node selection rules
└── tolerations: Run on tainted nodes (like masters)

Example: Only on GPU nodes
spec:
  nodeSelector:
    gpu: "true"
```

---

## When to Use Each Primitive

### Decision Tree

```
Need to run a task?
├── Runs continuously?
│   ├── Stateless?
│   │   └── Use: Deployment
│   └── Stateful (needs stable identity/storage)?
│       └── Use: StatefulSet
├── Runs once?
│   └── Use: Job
├── Runs on schedule?
│   └── Use: CronJob
└── One per node?
    └── Use: DaemonSet
```

### Real-World Examples

#### Web Application (Deployment)

```yaml
# Stateless web app: any pod can handle any request
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

**Why Deployment?**
- No local state
- Any pod is identical
- Can scale up/down easily
- Fast rolling updates

#### Database (StatefulSet)

```yaml
# Stateful database: each pod needs unique identity
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 50Gi
```

**Why StatefulSet?**
- Needs persistent data
- Each replica has unique data
- Ordered startup (primary first)
- Stable network identity for replication

#### Database Migration (Job)

```yaml
# One-time migration task
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: flyway/flyway
        command: ["flyway", "migrate"]
      restartPolicy: OnFailure
```

**Why Job?**
- Runs once to completion
- Automatic retries if fails
- Tracks success/failure
- Doesn't need to run continuously

#### Daily Backup (CronJob)

```yaml
# Scheduled backup task
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup
spec:
  schedule: "0 3 * * *"  # 3 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: backup-tool:latest
          restartPolicy: OnFailure
```

**Why CronJob?**
- Needs to run on schedule
- One-time task each run
- Automatic cleanup of old jobs
- Kubernetes manages scheduling

#### Monitoring Agent (DaemonSet)

```yaml
# Monitoring on every node
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring
spec:
  template:
    spec:
      containers:
      - name: agent
        image: monitoring-agent:latest
```

**Why DaemonSet?**
- Must run on every node
- Monitors node-level metrics
- Automatically scales with cluster
- Removed when node removed

---

## 📊 Quick Reference Table

| Primitive | Purpose | Replicas | Identity | Storage | Example Use |
|-----------|---------|----------|----------|---------|-------------|
| **Deployment** | Stateless apps | Yes | Random | Ephemeral/Shared | Web apps, APIs |
| **StatefulSet** | Stateful apps | Yes | Stable | Persistent per pod | Databases |
| **DaemonSet** | Per-node apps | One/node | Random | Usually ephemeral | Monitoring, logging |
| **Job** | Run-once tasks | Configurable | Random | Ephemeral | Migrations, batch |
| **CronJob** | Scheduled tasks | Per schedule | Random | Ephemeral | Backups, cleanup |

---

## 🎓 Configuration Management Summary

| Type | Use Case | Security | Example |
|------|----------|----------|---------|
| **ConfigMap** | Non-sensitive config | Not encrypted | Database host, log level |
| **Secret** | Sensitive data | Base64, can encrypt | Passwords, API keys |
| **Environment** | Simple values | Not secure | App version, defaults |

---

## 💡 Best Practices

### General Guidelines

1. **Use the right primitive**
   - Don't use StatefulSet for stateless apps
   - Don't use Deployment for databases
   - Use Jobs for one-time tasks, not Deployments

2. **Configuration management**
   - ConfigMaps for non-sensitive data
   - Secrets for credentials (enable encryption!)
   - Never hardcode credentials in images

3. **Storage**
   - Request only what you need (costs money!)
   - Use appropriate StorageClass
   - Set retention policies (Retain vs Delete)
   - Regular backups (VolumeSnapshots)

4. **Resource limits**
   - Always set CPU and memory requests
   - Set limits to prevent resource exhaustion
   - Monitor actual usage and adjust

### 🏢 → ☁️ Migration Tips

**If you currently:**
- Run web servers → Use Deployments
- Run databases → Use StatefulSets with PVCs
- Use cron jobs → Use CronJobs
- Run monitoring on all servers → Use DaemonSets
- Run batch scripts → Use Jobs

---

## 🚀 What's Next?

### In Activity 4

You'll use **Deployments** to deploy the microservices Todo app:
- Frontend Deployment
- Backend Deployment
- Simple and stateless

### In Activity 5, Part A (Hands-On)

You'll get hands-on experience with:
- **Jobs & CronJobs**: Database backup tasks
- **Secrets & ConfigMaps**: Manage application configuration
- **StatefulSets**: Deploy MySQL with persistent storage
- **PersistentVolumes**: Work with EBS volumes

### In Activity 5, Part B

You'll dive into **networking** and **services**.

### In Activity 5, Part C

You'll implement a complete **CI/CD pipeline** with Jenkins.

---

## 📚 Additional Resources

### Official Documentation

- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [DaemonSets](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

### Hands-On Practice

For interactive practice:
- [Kubernetes By Example](https://kubernetesbyexample.com/)
- [Play with Kubernetes](https://labs.play-with-k8s.com/)
- [Katacoda Kubernetes](https://www.katacoda.com/courses/kubernetes)

---

## ✅ Knowledge Check

After reading this guide, you should be able to answer:

- [ ] What's the difference between a Deployment and StatefulSet?
- [ ] When would you use a Job vs a CronJob?
- [ ] What's the difference between ConfigMap and Secret?
- [ ] How does storage work in Kubernetes (PV/PVC)?
- [ ] When should you use a DaemonSet?
- [ ] What access modes exist for Persistent Volumes?

---

**Ready to proceed with Activity 4?** Continue to the main [README.md](README.md) to start the scripted setup!

**Want hands-on practice?** Complete Activity 4, then move to Activity 5, Part A for practical labs on these primitives.

---

**Remember:** Understanding these primitives is key to building production-ready Kubernetes applications! 🚀

