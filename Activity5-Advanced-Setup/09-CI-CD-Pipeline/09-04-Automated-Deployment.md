# Automated Deployment - End-to-End Workflow

Complete the CI/CD pipeline with automated deployments triggered by Git commits.

---

## 🎯 Learning Objectives

- ✅ Implement GitOps workflow
- ✅ Configure automatic deployments
- ✅ Set up deployment strategies
- ✅ Implement blue-green deployments
- ✅ Monitor deployments

---

## ⏱️ Time Estimate

**35-40 minutes**

---

## Complete Workflow

```
Developer → Git Push → Webhook → Jenkins Pipeline
   ↓
Build & Test → Docker Image → ECR → Deploy to K8s → Monitor
```

---

## Lab 1: GitOps Workflow

### Repository Structure

```
todo-app/
├── src/                    # Application code
├── Dockerfile             # Container definition
├── Jenkinsfile           # Pipeline definition
├── k8s/                   # Kubernetes manifests
│   ├── base/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── overlays/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
├── tests/                 # Test files
└── README.md
```

### Kustomize for Multi-Environment

```yaml
# k8s/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      containers:
      - name: todo-app
        image: TODO_APP_IMAGE
        ports:
        - containerPort: 3000
```

```yaml
# k8s/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: production
bases:
  - ../../base
replicas:
  - name: todo-app
    count: 5
patches:
  - patch: |-
      - op: replace
        path: /spec/template/spec/containers/0/resources
        value:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

---

## Lab 2: Deployment Strategies

### Rolling Update (Default)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Add 1 extra pod during update
      maxUnavailable: 1  # Allow 1 pod to be unavailable
```

### Blue-Green Deployment

```groovy
// Jenkinsfile - Blue-Green
stage('Blue-Green Deploy') {
    steps {
        container('kubectl') {
            sh '''
                # Deploy green version
                kubectl apply -f k8s/green-deployment.yaml
                
                # Wait for green to be ready
                kubectl wait --for=condition=available \
                  deployment/todo-app-green --timeout=5m
                
                # Switch service to green
                kubectl patch service todo-app \
                  -p '{"spec":{"selector":{"version":"green"}}}'
                
                # Wait and verify
                sleep 30
                
                # If successful, delete blue
                kubectl delete deployment todo-app-blue
                
                # Rename green to blue for next deployment
                kubectl get deployment todo-app-green \
                  -o yaml | sed 's/green/blue/g' | kubectl apply -f -
                kubectl delete deployment todo-app-green
            '''
        }
    }
}
```

### Canary Deployment

```yaml
# Canary deployment - 10% traffic
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app-canary
  labels:
    version: canary
spec:
  replicas: 1  # 10% of stable (stable has 9 replicas)
  selector:
    matchLabels:
      app: todo-app
      version: canary
```

```groovy
stage('Canary Deploy') {
    steps {
        container('kubectl') {
            sh '''
                # Deploy canary (10% traffic)
                kubectl apply -f k8s/canary-deployment.yaml
                
                # Monitor for 5 minutes
                sleep 300
                
                # Check error rate
                ERROR_RATE=$(kubectl logs -l version=canary --tail=1000 | \
                  grep ERROR | wc -l)
                
                if [ $ERROR_RATE -gt 10 ]; then
                    echo "Canary failed - rolling back"
                    kubectl delete deployment todo-app-canary
                    exit 1
                fi
                
                # Promote canary to stable
                kubectl apply -f k8s/stable-deployment.yaml
                kubectl delete deployment todo-app-canary
            '''
        }
    }
}
```

---

## Lab 3: Monitoring Deployments

### Add Health Checks

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: todo-app
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
```

### Monitor in Pipeline

```groovy
stage('Monitor Deployment') {
    steps {
        container('kubectl') {
            sh '''
                # Watch rollout
                kubectl rollout status deployment/todo-app -w
                
                # Check pod health
                kubectl get pods -l app=todo-app
                
                # Check events
                kubectl get events --sort-by='.lastTimestamp' | \
                  grep todo-app | tail -10
                
                # Verify readiness
                READY_PODS=$(kubectl get deployment todo-app \
                  -o jsonpath='{.status.readyReplicas}')
                DESIRED_PODS=$(kubectl get deployment todo-app \
                  -o jsonpath='{.spec.replicas}')
                
                if [ "$READY_PODS" != "$DESIRED_PODS" ]; then
                    echo "Deployment failed: $READY_PODS/$DESIRED_PODS ready"
                    exit 1
                fi
            '''
        }
    }
}
```

---

## Lab 4: Rollback Strategy

### Automatic Rollback

```groovy
post {
    failure {
        script {
            if (env.STAGE_NAME == 'Verify Deployment') {
                container('kubectl') {
                    sh '''
                        echo "Deployment verification failed - rolling back"
                        kubectl rollout undo deployment/todo-app
                        kubectl rollout status deployment/todo-app
                    '''
                }
            }
        }
    }
}
```

### Manual Rollback Commands

```bash
# View deployment history
kubectl rollout history deployment/todo-app

# Rollback to previous version
kubectl rollout undo deployment/todo-app

# Rollback to specific revision
kubectl rollout undo deployment/todo-app --to-revision=3

# Check rollback status
kubectl rollout status deployment/todo-app
```

---

## Lab 5: Complete End-to-End Test

### Step 1: Make Code Change

```bash
# Clone repository
git clone https://github.com/your-org/todo-app
cd todo-app

# Make a change
echo "console.log('New feature');" >> src/index.js

# Commit and push
git add .
git commit -m "Add new feature"
git push origin main
```

### Step 2: Watch Pipeline

1. Jenkins receives webhook
2. Pipeline starts automatically
3. Watch stages complete:
   - Checkout
   - Build
   - Test
   - Docker build
   - Push to ECR
   - Deploy to K8s
   - Verify

### Step 3: Verify Deployment

```bash
# Check deployment
kubectl get deployment todo-app

# Check pods
kubectl get pods -l app=todo-app

# Check image version
kubectl describe deployment todo-app | grep Image

# Test application
curl http://$(kubectl get service todo-app \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

---

## Lab 6: Dashboard and Monitoring

### Jenkins Blue Ocean

1. Install Blue Ocean plugin
2. Access at: `http://jenkins-url/blue`
3. View pipeline visualization
4. Monitor builds in real-time

### Kubernetes Dashboard

```bash
# Deploy dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:dashboard-admin

# Get token
kubectl -n kubernetes-dashboard create token dashboard-admin

# Port forward
kubectl port-forward -n kubernetes-dashboard \
  svc/kubernetes-dashboard 8443:443

# Access at: https://localhost:8443
```

---

## 💡 Production Best Practices

### CI/CD Checklist

```yaml
Code Quality:
├── ✓ Automated tests
├── ✓ Code linting
├── ✓ Security scanning
└── ✓ Code coverage reports

Build:
├── ✓ Multi-stage Docker builds
├── ✓ Layer caching
├── ✓ Image scanning
└── ✓ Build artifacts stored

Deploy:
├── ✓ Infrastructure as Code
├── ✓ Blue-green or canary
├── ✓ Health checks
├── ✓ Automatic rollback
└── ✓ Deployment verification

Monitor:
├── ✓ Application logs
├── ✓ Metrics collection
├── ✓ Alerting configured
└── ✓ Dashboard access
```

### Security Best Practices

```yaml
1. Scan images for vulnerabilities
   - Use Trivy, Clair, or Snyk
   
2. Use least privilege
   - Minimum IAM permissions
   - RBAC for service accounts
   
3. Secrets management
   - Never commit secrets
   - Use Jenkins credentials store
   - Consider AWS Secrets Manager
   
4. Audit logging
   - Enable CloudWatch logs
   - Track deployments
   - Monitor access

5. Network security
   - Use Network Policies
   - Restrict pod-to-pod communication
   - Use AWS Security Groups
```

---

## 🧹 Cleanup

```bash
# Delete Jenkins
kubectl delete namespace jenkins

# Delete deployments
kubectl delete deployment todo-app -n production

# Delete ECR repository
aws ecr delete-repository \
  --repository-name todo-app \
  --force \
  --region ap-southeast-1
```

---

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [AWS ECR](https://docs.aws.amazon.com/ecr/)
- [GitOps with Kubernetes](https://www.gitops.tech/)

---

## ✅ Knowledge Check

- [ ] Understand GitOps workflow
- [ ] Implement deployment strategies
- [ ] Configure automatic deployments
- [ ] Set up monitoring and rollback
- [ ] Secure CI/CD pipeline

---

## 🎉 Congratulations!

You've completed **Part C: CI/CD Pipeline**!

You now have:
- ✅ Jenkins running on Kubernetes
- ✅ Automated builds and tests
- ✅ Docker images in ECR
- ✅ Automated deployments
- ✅ Monitoring and rollback
- ✅ Production-ready CI/CD pipeline

---

## 🚀 What's Next?

You've completed Activity 5! You now know:
- Part A: Kubernetes workloads (Jobs, Secrets, StatefulSets, Volumes)
- Part B: Networking and auto-scaling
- Part C: Complete CI/CD pipeline

**Consider exploring:**
- Service Mesh (Istio, Linkerd)
- Advanced monitoring (Prometheus, Grafana)
- Policy management (OPA, Kyverno)
- Multi-cluster management

---

**Amazing work!** You're now ready for production Kubernetes! 🎊🚀

