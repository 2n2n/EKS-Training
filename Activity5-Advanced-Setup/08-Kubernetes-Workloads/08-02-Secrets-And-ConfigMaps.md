# Secrets and ConfigMaps - Configuration Management

Welcome to the configuration management lab! Learn how to manage application configuration and sensitive data in Kubernetes.

---

## 🎯 Learning Objectives

By the end of this guide, you will:

- ✅ Create and use ConfigMaps for non-sensitive configuration
- ✅ Create and use Secrets for sensitive data
- ✅ Inject configuration as environment variables
- ✅ Mount configuration as files
- ✅ Update configuration without redeploying applications
- ✅ Understand encryption and security best practices

---

## ⏱️ Time Estimate

**Total Time: 30-35 minutes**

- ConfigMaps: 15 min
- Secrets: 15 min
- Best practices: 5 min

---

## 📋 Prerequisites

- Cluster running
- kubectl configured
- Basic understanding of Pods and environment variables

---

## Part 1: ConfigMaps

### What Are ConfigMaps?

**ConfigMaps** store non-sensitive configuration data as key-value pairs.

### 🏢 Traditional Configuration

```bash
# Traditional: Config files on disk
# /etc/myapp/config.ini
DATABASE_HOST=localhost
DATABASE_PORT=3306
LOG_LEVEL=info
MAX_CONNECTIONS=100

# Or environment variables in systemd
Environment="DATABASE_HOST=localhost"
Environment="LOG_LEVEL=info"
```

### ☁️ Kubernetes ConfigMaps

```yaml
# Centralized, version-controlled, environment-specific
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "mysql.default.svc.cluster.local"
  LOG_LEVEL: "info"
```

---

## Lab 1: Creating ConfigMaps

### Method 1: From Literal Values

```bash
kubectl create configmap app-config \
  --from-literal=DATABASE_HOST=mysql.default.svc.cluster.local \
  --from-literal=DATABASE_PORT=3306 \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100
```

### Method 2: From YAML File

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  DATABASE_HOST: "mysql.default.svc.cluster.local"
  DATABASE_PORT: "3306"
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  APP_MODE: "production"
  CACHE_ENABLED: "true"
EOF
```

### Method 3: From File

```bash
# Create a config file
cat > application.properties <<EOF
database.host=mysql.default.svc.cluster.local
database.port=3306
log.level=info
max.connections=100
EOF

# Create ConfigMap from file
kubectl create configmap app-properties \
  --from-file=application.properties
```

### View ConfigMaps

```bash
# List all ConfigMaps
kubectl get configmaps

# View specific ConfigMap
kubectl describe configmap app-config

# View as YAML
kubectl get configmap app-config -o yaml
```

---

## Lab 2: Using ConfigMaps as Environment Variables

### Step 1: Create ConfigMap

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
  namespace: default
data:
  APP_COLOR: "blue"
  APP_MODE: "production"
  GREETING: "Hello from Kubernetes!"
EOF
```

### Step 2: Create Pod Using ConfigMap

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: configmap-env-pod
  namespace: default
spec:
  containers:
  - name: test-container
    image: busybox:1.35
    command: ["/bin/sh", "-c"]
    args:
    - |
      echo "App Color: \$APP_COLOR"
      echo "App Mode: \$APP_MODE"
      echo "Greeting: \$GREETING"
      sleep 3600
    env:
    # Individual environment variables from ConfigMap
    - name: APP_COLOR
      valueFrom:
        configMapKeyRef:
          name: web-config
          key: APP_COLOR
    - name: APP_MODE
      valueFrom:
        configMapKeyRef:
          name: web-config
          key: APP_MODE
    - name: GREETING
      valueFrom:
        configMapKeyRef:
          name: web-config
          key: GREETING
EOF
```

### Step 3: Verify Environment Variables

```bash
# Wait for pod to be ready
kubectl wait --for=condition=ready pod/configmap-env-pod --timeout=60s

# Check logs
kubectl logs configmap-env-pod

# Execute command in pod to verify
kubectl exec configmap-env-pod -- env | grep APP_
```

### Alternative: Load All Keys as Environment Variables

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: configmap-envfrom-pod
  namespace: default
spec:
  containers:
  - name: test-container
    image: busybox:1.35
    command: ["/bin/sh", "-c", "env; sleep 3600"]
    envFrom:
    - configMapRef:
        name: web-config
EOF
```

```bash
# View all environment variables
kubectl logs configmap-envfrom-pod | grep -E "APP_|GREETING"
```

---

## Lab 3: Mounting ConfigMaps as Files

### Step 1: Create ConfigMap with File Content

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: default
data:
  nginx.conf: |
    server {
      listen 80;
      server_name localhost;
      
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
      
      location /health {
        access_log off;
        return 200 "healthy\n";
      }
    }
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>ConfigMap Demo</title></head>
    <body>
      <h1>Configuration from ConfigMap!</h1>
      <p>This HTML was loaded from a Kubernetes ConfigMap.</p>
    </body>
    </html>
EOF
```

### Step 2: Mount ConfigMap as Volume

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-configmap
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    volumeMounts:
    - name: config-volume
      mountPath: /etc/nginx/conf.d
      subPath: nginx.conf
    - name: html-volume
      mountPath: /usr/share/nginx/html/index.html
      subPath: index.html
  volumes:
  - name: config-volume
    configMap:
      name: nginx-config
      items:
      - key: nginx.conf
        path: nginx.conf
  - name: html-volume
    configMap:
      name: nginx-config
      items:
      - key: index.html
        path: index.html
EOF
```

### Step 3: Test Configuration

```bash
# Wait for pod
kubectl wait --for=condition=ready pod/nginx-configmap --timeout=60s

# Port forward to access nginx
kubectl port-forward pod/nginx-configmap 8080:80 &

# Test the health endpoint
curl http://localhost:8080/health

# Test the main page
curl http://localhost:8080/

# Stop port forward
pkill -f "kubectl port-forward"
```

---

## Part 2: Secrets

### What Are Secrets?

**Secrets** store sensitive information like passwords, tokens, and keys.

⚠️ **Important:** Base64 encoding is NOT encryption! Enable encryption at rest in production.

### 🏢 Traditional Secrets Management

```bash
# Traditional: Plain text or env files
# .env file
DB_PASSWORD=mypassword123
API_KEY=abc123xyz

Problems:
❌ Often committed to Git
❌ No access control
❌ No audit trail
❌ Hard to rotate
```

### ☁️ Kubernetes Secrets

```yaml
# Base64 encoded, access controlled, auditable
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  DB_PASSWORD: bXlwYXNzd29yZDEyMw==  # base64 encoded
```

---

## Lab 4: Creating Secrets

### Method 1: From Literal Values

```bash
kubectl create secret generic app-secrets \
  --from-literal=DB_PASSWORD=mySecretPassword123 \
  --from-literal=API_KEY=abc123xyz789 \
  --from-literal=JWT_SECRET=supersecret
```

### Method 2: From YAML (with base64 encoding)

```bash
# First, encode your secrets
echo -n "mySecretPassword123" | base64
# Output: bXlTZWNyZXRQYXNzd29yZDEyMw==

echo -n "abc123xyz789" | base64
# Output: YWJjMTIzeHl6Nzg5

# Create Secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
data:
  DB_PASSWORD: bXlTZWNyZXRQYXNzd29yZDEyMw==
  API_KEY: YWJjMTIzeHl6Nzg5
  JWT_SECRET: c3VwZXJzZWNyZXQ=
EOF
```

### Method 3: From File

```bash
# Create files with sensitive data
echo -n "admin" > username.txt
echo -n "P@ssw0rd!" > password.txt

# Create Secret from files
kubectl create secret generic db-credentials \
  --from-file=username=username.txt \
  --from-file=password=password.txt

# Clean up files
rm username.txt password.txt
```

### View Secrets (Safely)

```bash
# List secrets (values are hidden)
kubectl get secrets

# Describe secret (values are hidden)
kubectl describe secret app-secrets

# View encoded values
kubectl get secret app-secrets -o yaml

# Decode a specific value
kubectl get secret app-secrets -o jsonpath='{.data.DB_PASSWORD}' | base64 --decode
```

---

## Lab 5: Using Secrets as Environment Variables

### Step 1: Create a Secret

```bash
kubectl create secret generic mysql-credentials \
  --from-literal=root-password=rootPassword123 \
  --from-literal=user=appuser \
  --from-literal=password=appPassword456 \
  --from-literal=database=myappdb
```

### Step 2: Deploy MySQL Using Secret

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: mysql-with-secret
  labels:
    app: mysql
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysql-credentials
          key: root-password
    - name: MYSQL_USER
      valueFrom:
        secretKeyRef:
          name: mysql-credentials
          key: user
    - name: MYSQL_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysql-credentials
          key: password
    - name: MYSQL_DATABASE
      valueFrom:
        secretKeyRef:
          name: mysql-credentials
          key: database
    ports:
    - containerPort: 3306
EOF
```

### Step 3: Verify MySQL Started

```bash
# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod/mysql-with-secret --timeout=120s

# Check logs
kubectl logs mysql-with-secret | grep "ready for connections"

# Test connection (from inside the pod)
kubectl exec mysql-with-secret -- mysql -uappuser -pappPassword456 -e "SHOW DATABASES;"
```

---

## Lab 6: Mounting Secrets as Files

### Use Case: SSL/TLS Certificates

```bash
# Create dummy certificate files
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=myapp.example.com"

# Create TLS secret
kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Clean up files
rm tls.key tls.crt
```

### Deploy Nginx with TLS

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-tls
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 443
    volumeMounts:
    - name: tls-certs
      mountPath: /etc/nginx/ssl
      readOnly: true
  volumes:
  - name: tls-certs
    secret:
      secretName: tls-secret
EOF
```

### Verify Certificates Mounted

```bash
# List files in the certificate directory
kubectl exec nginx-tls -- ls -la /etc/nginx/ssl

# View certificate details (first few lines)
kubectl exec nginx-tls -- cat /etc/nginx/ssl/tls.crt | head -5
```

---

## Lab 7: Real-World Example - Complete Application

### Step 1: Create All Configuration

```bash
# ConfigMap for app settings
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
  namespace: default
data:
  APP_NAME: "My Web App"
  APP_ENV: "production"
  LOG_LEVEL: "info"
  DATABASE_HOST: "mysql-with-secret"
  DATABASE_PORT: "3306"
  CACHE_ENABLED: "true"
  MAX_CONNECTIONS: "100"
EOF

# Secret for sensitive data
kubectl create secret generic webapp-secrets \
  --from-literal=DATABASE_USER=appuser \
  --from-literal=DATABASE_PASSWORD=appPassword456 \
  --from-literal=SESSION_SECRET=randomSecret123 \
  --from-literal=API_KEY=production-api-key-xyz
```

### Step 2: Deploy Application

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: default
spec:
  replicas: 2
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
        image: busybox:1.35
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "=== Application Configuration ==="
          echo "App Name: \$APP_NAME"
          echo "Environment: \$APP_ENV"
          echo "Database: \$DATABASE_USER@\$DATABASE_HOST:\$DATABASE_PORT"
          echo "Log Level: \$LOG_LEVEL"
          echo "Cache: \$CACHE_ENABLED"
          echo "Session Secret: [HIDDEN]"
          echo "API Key: [HIDDEN]"
          echo "=== Starting Application ==="
          sleep 3600
        env:
        # From ConfigMap
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: APP_NAME
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: APP_ENV
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: LOG_LEVEL
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_HOST
        - name: DATABASE_PORT
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_PORT
        - name: CACHE_ENABLED
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: CACHE_ENABLED
        # From Secret
        - name: DATABASE_USER
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: DATABASE_USER
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: DATABASE_PASSWORD
        - name: SESSION_SECRET
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: SESSION_SECRET
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: webapp-secrets
              key: API_KEY
EOF
```

### Step 3: Verify Deployment

```bash
# Check deployment
kubectl get deployment webapp

# Check pods
kubectl get pods -l app=webapp

# View logs from one pod
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

---

## Lab 8: Updating Configuration

### Update ConfigMap

```bash
# Update ConfigMap
kubectl patch configmap webapp-config -p '{"data":{"LOG_LEVEL":"debug"}}'

# Verify update
kubectl get configmap webapp-config -o yaml | grep LOG_LEVEL
```

### Restart Pods to Pick Up Changes

```bash
# ConfigMaps/Secrets in env vars require pod restart
kubectl rollout restart deployment webapp

# Watch rollout
kubectl rollout status deployment webapp

# Check new pod logs
POD_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME | grep "Log Level"
```

### 💡 Auto-Reload Configuration

For mounted volumes, changes appear automatically (may take 1-2 minutes).
For environment variables, pods must be restarted.

```yaml
# To trigger automatic restarts on ConfigMap changes,
# add a checksum annotation to pod template:

spec:
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

---

## 🔒 Security Best Practices

### Secrets Security

```yaml
1. Enable Encryption at Rest (EKS)
   # AWS KMS integration for EKS
   eksctl utils enable-secrets-encryption \
     --cluster=<cluster-name> \
     --key-arn=<kms-key-arn>

2. Use RBAC to Limit Access
   # Only specific service accounts can read secrets
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   rules:
   - apiGroups: [""]
     resources: ["secrets"]
     resourceNames: ["app-secrets"]
     verbs: ["get"]

3. Use External Secrets Managers (Production)
   # AWS Secrets Manager
   # HashiCorp Vault
   # External Secrets Operator

4. Never commit secrets to Git
   # Add to .gitignore:
   *-secrets.yaml
   *.secret
```

### ConfigMap Best Practices

```yaml
1. Separate by Environment
   configmap-dev.yaml
   configmap-staging.yaml
   configmap-production.yaml

2. Use Meaningful Names
   ✅ database-config
   ✅ redis-cache-config
   ❌ config
   ❌ app-cm

3. Add Labels
   metadata:
     labels:
       app: myapp
       component: backend
       environment: production

4. Document Values
   data:
     MAX_CONNECTIONS: "100"  # Maximum database connections
     TIMEOUT: "30"           # Request timeout in seconds
```

---

## 🧹 Cleanup

```bash
# Delete all resources from labs
kubectl delete pod configmap-env-pod configmap-envfrom-pod nginx-configmap
kubectl delete pod mysql-with-secret nginx-tls
kubectl delete deployment webapp
kubectl delete configmap app-config web-config nginx-config webapp-config app-properties
kubectl delete secret app-secrets mysql-credentials tls-secret webapp-secrets db-credentials
```

---

## 📊 ConfigMap vs Secret vs Environment Variables

| Method | Security | Updates | Use Case |
|--------|----------|---------|----------|
| **ConfigMap** | Not encrypted | Requires pod restart (env) | Non-sensitive config |
| **Secret** | Base64, can encrypt | Requires pod restart (env) | Passwords, keys |
| **Env (hardcoded)** | Plain text in YAML | Requires rebuild | Never for secrets! |
| **External Secrets** | Encrypted, managed | Automatic sync | Production secrets |

---

## 💡 When to Use What

```
Use ConfigMap:
├── Application settings
├── Feature flags
├── Environment-specific config
├── Non-sensitive URLs
└── Configuration files

Use Secrets:
├── Database passwords
├── API keys and tokens
├── TLS certificates
├── SSH keys
└── OAuth credentials

Use External Secrets Manager:
├── Production environments
├── Compliance requirements
├── Secret rotation needed
├── Centralized secret management
└── Audit requirements
```

---

## 📚 Additional Resources

- [ConfigMaps Documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [AWS Secrets Manager CSI Driver](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html)

---

## ✅ Knowledge Check

You should now be able to:

- [ ] Create ConfigMaps and Secrets
- [ ] Inject configuration as environment variables
- [ ] Mount configuration as files
- [ ] Update configuration
- [ ] Understand security best practices
- [ ] Choose appropriate configuration method

---

## 🚀 What's Next?

**Continue to:** [08-03-StatefulSets.md](08-03-StatefulSets.md) to learn about stateful applications with persistent storage.

---

**Excellent work!** You now know how to manage configuration securely in Kubernetes! 🔐

