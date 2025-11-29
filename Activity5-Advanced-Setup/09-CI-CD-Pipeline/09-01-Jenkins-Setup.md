# Jenkins Setup on Kubernetes

Welcome to CI/CD with Jenkins! This guide covers setting up Jenkins on Kubernetes for automated deployments.

---

## 🎯 Learning Objectives

By the end of this guide, you will:

- ✅ Deploy Jenkins on Kubernetes
- ✅ Configure persistent storage for Jenkins
- ✅ Set up Jenkins with proper security
- ✅ Install required plugins
- ✅ Configure kubectl access for deployments
- ✅ Access Jenkins UI

---

## ⏱️ Time Estimate

**Total Time: 45-60 minutes**

- Deploy Jenkins: 20 min
- Configuration: 20 min
- Plugin installation: 15 min
- Testing: 10 min

---

## 📋 Prerequisites

- EKS cluster running
- kubectl configured
- Understanding of Kubernetes basics
- ECR repository (will create if needed)

---

## Why Jenkins on Kubernetes?

### Benefits

```
✅ Scalable build agents (dynamic pods)
✅ Infrastructure as Code
✅ Easy disaster recovery (persistent storage)
✅ Cost-effective (only runs when needed)
✅ Integrates with K8s resources
✅ Can deploy to same cluster
```

### 🏢 Traditional Jenkins

```bash
# Traditional: Jenkins on dedicated server
- Fixed resources
- Manual scaling
- Server maintenance required
- Complex backup procedures
- Static build agents

Problems:
❌ Underutilized during low activity
❌ Resource constraints during peaks
❌ Complex maintenance
❌ Expensive dedicated infrastructure
```

### ☁️ Jenkins on Kubernetes

```yaml
# Dynamic, scalable, cost-effective
- Runs as pods
- Auto-scaling build agents
- Kubernetes handles maintenance
- Simple backup (PVC snapshots)
- Dynamic agent pods

Benefits:
✅ Pay for what you use
✅ Scales automatically
✅ Easy maintenance
✅ Simple backup/restore
```

---

## Lab 1: Deploy Jenkins

### Step 1: Create Namespace

```bash
kubectl create namespace jenkins

# Set context for convenience
kubectl config set-context --current --namespace=jenkins
```

### Step 2: Create Service Account

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create","delete","get","list","patch","update","watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create","delete","get","list","patch","update","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
- kind: ServiceAccount
  name: jenkins
  namespace: jenkins
EOF
```

### Step 3: Create Persistent Volume Claim

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 20Gi
EOF
```

### Step 4: Deploy Jenkins

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      serviceAccountName: jenkins
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 50000
          name: agent
        env:
        - name: JAVA_OPTS
          value: "-Djenkins.install.runSetupWizard=false"
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 90
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
          timeoutSeconds: 5
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
EOF
```

### Step 5: Create Service

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
    name: http
  - port: 50000
    targetPort: 50000
    name: agent
  selector:
    app: jenkins
EOF
```

### Step 6: Wait for Jenkins to Start

```bash
# Watch pod status
kubectl get pods -n jenkins -w

# Wait for ready
kubectl wait --for=condition=ready pod -l app=jenkins -n jenkins --timeout=300s

# Check logs
kubectl logs -f -l app=jenkins -n jenkins
```

---

## Lab 2: Access Jenkins

### Step 1: Get Load Balancer URL

```bash
# Get external URL (takes 2-3 minutes)
kubectl get service jenkins -n jenkins

# Wait for EXTERNAL-IP
JENKINS_URL=$(kubectl get service jenkins -n jenkins -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Jenkins URL: http://$JENKINS_URL"
```

### Step 2: Get Initial Admin Password

```bash
# Get password from logs
kubectl logs -l app=jenkins -n jenkins | grep -A 5 "Jenkins initial setup"

# Or read from file
kubectl exec -n jenkins -it $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 3: Access Jenkins UI

```bash
# Open in browser
echo "Open: http://$JENKINS_URL"

# Use the initial admin password to login
```

---

## Lab 3: Jenkins Initial Configuration

### Step 1: Install Suggested Plugins

1. After login, Jenkins will show plugin installation page
2. Click "Install suggested plugins"
3. Wait for installation (5-10 minutes)

### Step 2: Create Admin User

1. Fill in admin user details:
   - Username: `admin`
   - Password: (choose secure password)
   - Full name: `Admin User`
   - Email: your-email@example.com

2. Click "Save and Continue"

### Step 3: Jenkins URL

1. Confirm Jenkins URL
2. Click "Save and Finish"
3. Click "Start using Jenkins"

---

## Lab 4: Install Required Plugins

### Step 1: Navigate to Plugin Manager

1. Click "Manage Jenkins"
2. Click "Manage Plugins"
3. Go to "Available" tab

### Step 2: Install Plugins

Search and install these plugins:
- **Kubernetes**: For dynamic build agents
- **Docker Pipeline**: For Docker commands in pipeline
- **AWS Credentials**: For AWS authentication
- **Pipeline**: For Jenkinsfile support (usually pre-installed)
- **Git**: For Git integration (usually pre-installed)
- **Blue Ocean**: Modern UI (optional)

Install steps:
1. Check boxes next to plugins
2. Click "Install without restart"
3. Wait for installation
4. Restart Jenkins if needed

---

## Lab 5: Configure Kubernetes Plugin

### Step 1: Configure Kubernetes Cloud

1. Go to "Manage Jenkins" → "Manage Nodes and Clouds"
2. Click "Configure Clouds"
3. Click "Add a new cloud" → "Kubernetes"

### Step 2: Kubernetes Configuration

Fill in:
- **Name**: `kubernetes`
- **Kubernetes URL**: `https://kubernetes.default`
- **Kubernetes Namespace**: `jenkins`
- **Jenkins URL**: `http://jenkins.jenkins.svc.cluster.local`
- **Jenkins tunnel**: `jenkins.jenkins.svc.cluster.local:50000`

Click "Test Connection" - should show "Connected to Kubernetes"

### Step 3: Pod Template

1. Click "Pod Templates" → "Add Pod Template"
2. Configure:
   - **Name**: `jenkins-agent`
   - **Namespace**: `jenkins`
   - **Labels**: `jenkins-agent`

3. Add Container:
   - **Name**: `jnlp`
   - **Docker image**: `jenkins/inbound-agent:latest`
   - **Working directory**: `/home/jenkins/agent`

4. Save configuration

---

## Lab 6: Configure AWS Credentials

### Step 1: Create AWS IAM User (if needed)

```bash
# Create IAM user for Jenkins
aws iam create-user --user-name jenkins-ci

# Attach ECR permissions
aws iam attach-user-policy \
  --user-name jenkins-ci \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# Create access key
aws iam create-access-key --user-name jenkins-ci

# Save the AccessKeyId and SecretAccessKey
```

### Step 2: Add AWS Credentials in Jenkins

1. Go to "Manage Jenkins" → "Manage Credentials"
2. Click "(global)" domain
3. Click "Add Credentials"

Fill in:
- **Kind**: AWS Credentials
- **ID**: `aws-credentials`
- **Access Key ID**: (from above)
- **Secret Access Key**: (from above)
- **Description**: Jenkins AWS Access

Click "OK"

---

## Lab 7: Configure kubectl

### Step 1: Install kubectl in Jenkins

```bash
# Update Jenkins deployment to include kubectl
kubectl set image deployment/jenkins jenkins=jenkins/jenkins:lts -n jenkins

# Or update deployment with custom image
# Create a custom Dockerfile:
# FROM jenkins/jenkins:lts
# USER root
# RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
#   && chmod +x kubectl \
#   && mv kubectl /usr/local/bin/
# USER jenkins
```

### Alternative: Add kubectl to Agent

Create custom agent image with kubectl:

```dockerfile
FROM jenkins/inbound-agent:latest
USER root
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x kubectl \
  && mv kubectl /usr/local/bin/
USER jenkins
```

---

## 💡 Best Practices

### Security

```yaml
1. Change default admin password immediately
2. Enable CSRF protection (default)
3. Use RBAC for user permissions
4. Store secrets in Jenkins credentials store
5. Enable audit logging
6. Use HTTPS (configure ALB with SSL)

# Example: Configure security realm
Manage Jenkins → Configure Global Security:
├── Security Realm: Jenkins' own user database
├── Authorization: Matrix-based security
└── Prevent Cross Site Request Forgery exploits: ✓
```

### Backup Strategy

```bash
# Regular backups of Jenkins home
1. Use VolumeSnapshots for PVC
2. Backup Jenkins configuration
3. Store pipeline definitions in Git (Jenkinsfile)
4. Document plugin versions

# Create snapshot
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: jenkins-backup-$(date +%Y%m%d)
  namespace: jenkins
spec:
  volumeSnapshotClassName: ebs-snapshot-class
  source:
    persistentVolumeClaimName: jenkins-pvc
EOF
```

### Performance Tuning

```yaml
# Adjust resources based on usage
resources:
  requests:
    memory: "2Gi"  # Increase for large builds
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"

# Java heap size
env:
- name: JAVA_OPTS
  value: "-Xmx2048m -Xms1024m"
```

---

## 🔍 Troubleshooting

### Jenkins Won't Start

```bash
# Check pod status
kubectl describe pod -l app=jenkins -n jenkins

# Check logs
kubectl logs -l app=jenkins -n jenkins --tail=100

# Common issues:
# - Insufficient memory
# - PVC not bound
# - Image pull errors
```

### Can't Access UI

```bash
# Check service
kubectl get service jenkins -n jenkins

# Check if LoadBalancer provisioned
kubectl describe service jenkins -n jenkins

# Port forward as alternative
kubectl port-forward -n jenkins svc/jenkins 8080:80

# Access at: http://localhost:8080
```

### Pods Not Launching

```bash
# Check service account permissions
kubectl get clusterrolebinding jenkins

# Check pod template configuration
# In Jenkins UI: Manage Jenkins → Configure Clouds → Kubernetes

# Test agent pod manually
kubectl run test-agent --image=jenkins/inbound-agent:latest -n jenkins --rm -it -- /bin/bash
```

---

## 🧹 Cleanup (Optional)

```bash
# To remove Jenkins completely
kubectl delete namespace jenkins

# This deletes:
# - Jenkins deployment
# - Services
# - PVC (and data!)
# - Service accounts
# - RBAC rules
```

---

## 📚 Additional Resources

- [Jenkins on Kubernetes Documentation](https://www.jenkins.io/doc/book/installing/kubernetes/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Jenkins Docker Hub](https://hub.docker.com/r/jenkins/jenkins)

---

## ✅ Knowledge Check

You should now be able to:

- [ ] Deploy Jenkins on Kubernetes
- [ ] Configure persistent storage
- [ ] Access Jenkins UI
- [ ] Install plugins
- [ ] Configure Kubernetes integration
- [ ] Set up AWS credentials

---

## 🚀 What's Next?

**Continue to:** [09-02-ECR-Integration.md](09-02-ECR-Integration.md) to configure AWS ECR integration for Docker images.

---

**Great job!** Jenkins is now running on your Kubernetes cluster! 🎉

