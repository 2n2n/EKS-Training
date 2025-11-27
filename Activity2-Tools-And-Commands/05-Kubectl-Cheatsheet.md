# kubectl Cheatsheet

Quick reference for kubectl commands - your daily Kubernetes tool.

---

## 🎯 Cluster Info

```bash
# Cluster information
kubectl cluster-info

# API server address
kubectl cluster-info | grep "Kubernetes control plane"

# Cluster version
kubectl version

# Get current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context my-cluster

# View full config
kubectl config view
```

---

## 📋 Get Resources

```bash
# Pods
kubectl get pods
kubectl get pods -o wide  # More details
kubectl get pods --all-namespaces  # All namespaces
kubectl get pods -n kube-system  # Specific namespace

# Nodes
kubectl get nodes
kubectl get nodes -o wide

# Services
kubectl get services
kubectl get svc  # Short name

# Deployments
kubectl get deployments
kubectl get deploy  # Short name

# All resources
kubectl get all
kubectl get all -n kube-system

# Specific resource types
kubectl get pods,services,deployments
```

---

## 📝 Describe Resources (Detailed Info)

```bash
# Describe pod
kubectl describe pod my-pod

# Describe node
kubectl describe node my-node

# Describe service
kubectl describe service my-service

# Describe deployment
kubectl describe deployment my-app

# Short syntax
kubectl describe po/my-pod  # pod
kubectl describe svc/my-service  # service
kubectl describe deploy/my-app  # deployment
```

---

## 🚀 Create Resources

```bash
# Create from YAML file
kubectl create -f deployment.yaml

# Apply from YAML (create or update)
kubectl apply -f deployment.yaml

# Apply entire directory
kubectl apply -f ./manifests/

# Create namespace
kubectl create namespace dev

# Create deployment (imperative)
kubectl create deployment nginx --image=nginx

# Create service (imperative)
kubectl create service clusterip my-service --tcp=80:8080

# Dry run (preview without creating)
kubectl create -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --dry-run=client
```

---

## ✏️ Edit Resources

```bash
# Edit deployment
kubectl edit deployment my-app

# Edit service
kubectl edit service my-service

# Edit pod (limited - use deployments instead)
kubectl edit pod my-pod

# Set image (rolling update)
kubectl set image deployment/my-app container-name=my-app:v2

# Scale deployment
kubectl scale deployment my-app --replicas=5

# Autoscale
kubectl autoscale deployment my-app --min=2 --max=10 --cpu-percent=80
```

---

## 🗑️ Delete Resources

```bash
# Delete pod
kubectl delete pod my-pod

# Delete deployment
kubectl delete deployment my-app

# Delete service
kubectl delete service my-service

# Delete from YAML
kubectl delete -f deployment.yaml

# Delete all resources of type
kubectl delete pods --all

# Force delete (stuck resources)
kubectl delete pod my-pod --grace-period=0 --force

# Delete namespace (deletes everything in it!)
kubectl delete namespace dev
```

---

## 📄 Logs & Debugging

```bash
# View logs
kubectl logs my-pod

# Follow logs (live)
kubectl logs -f my-pod

# Last 100 lines
kubectl logs --tail=100 my-pod

# Logs from specific container (multi-container pod)
kubectl logs my-pod -c container-name

# Previous container logs (after restart)
kubectl logs my-pod --previous

# All pods with label
kubectl logs -l app=my-app

# Shell into container
kubectl exec -it my-pod -- bash
kubectl exec -it my-pod -- sh  # If bash not available

# Run command in container
kubectl exec my-pod -- ls /app
kubectl exec my-pod -- env

# Copy files
kubectl cp my-pod:/path/to/file ./local-file
kubectl cp ./local-file my-pod:/path/to/file

# Port forward (access pod locally)
kubectl port-forward my-pod 8080:80
# Access at: http://localhost:8080
```

---

## 🔍 Resource Status

```bash
# Pod status
kubectl get pods --field-selector=status.phase=Running
kubectl get pods --field-selector=status.phase=Pending

# Watch resources (auto-refresh)
kubectl get pods --watch
kubectl get pods -w  # Short form

# Resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods
kubectl top pod my-pod

# Events
kubectl get events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n kube-system
```

---

## 🏷️ Labels & Selectors

```bash
# Show labels
kubectl get pods --show-labels

# Filter by label
kubectl get pods -l app=my-app
kubectl get pods -l environment=production
kubectl get pods -l 'environment in (production,staging)'

# Add label
kubectl label pod my-pod environment=production

# Remove label
kubectl label pod my-pod environment-

# Update label
kubectl label pod my-pod environment=staging --overwrite
```

---

## 🎯 Namespaces

```bash
# List namespaces
kubectl get namespaces
kubectl get ns  # Short

# Create namespace
kubectl create namespace dev

# Set default namespace for context
kubectl config set-context --current --namespace=dev

# Get resources in namespace
kubectl get pods -n dev

# Get resources in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A  # Short form

# Delete namespace
kubectl delete namespace dev
```

---

## 📦 Deployments & Rolling Updates

```bash
# Create deployment
kubectl create deployment my-app --image=my-app:v1 --replicas=3

# Update image (rolling update)
kubectl set image deployment/my-app my-app=my-app:v2

# Check rollout status
kubectl rollout status deployment/my-app

# Rollout history
kubectl rollout history deployment/my-app

# Undo rollout (rollback)
kubectl rollout undo deployment/my-app

# Rollback to specific revision
kubectl rollout undo deployment/my-app --to-revision=2

# Pause rollout
kubectl rollout pause deployment/my-app

# Resume rollout
kubectl rollout resume deployment/my-app

# Restart deployment (recreate pods)
kubectl rollout restart deployment/my-app
```

---

## 🌐 Services & Networking

```bash
# Get services
kubectl get services

# Get endpoints
kubectl get endpoints

# Create ClusterIP service
kubectl expose deployment my-app --port=80 --target-port=8080

# Create NodePort service
kubectl expose deployment my-app --type=NodePort --port=80

# Get service URL (Minikube)
minikube service my-app --url

# Test service connectivity
kubectl run test --image=busybox --rm -it --restart=Never -- wget -O- my-service:80
```

---

## 📊 Resource Quotas & Limits

```bash
# View resource quotas
kubectl get resourcequotas
kubectl describe resourcequota my-quota

# View limit ranges
kubectl get limitranges
kubectl describe limitrange my-limits
```

---

## 🔐 ConfigMaps & Secrets

```bash
# Create ConfigMap from literal
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2

# Create ConfigMap from file
kubectl create configmap my-config --from-file=config.properties

# Get ConfigMaps
kubectl get configmaps
kubectl get cm  # Short

# Describe ConfigMap
kubectl describe configmap my-config

# Create Secret from literal
kubectl create secret generic my-secret --from-literal=password=secret123

# Create Secret from file
kubectl create secret generic my-secret --from-file=./credentials.txt

# Get Secrets
kubectl get secrets

# Decode secret
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 --decode
```

---

## 🧪 Testing & Troubleshooting

```bash
# Run temporary pod for testing
kubectl run test --image=busybox --rm -it --restart=Never -- sh

# Test DNS
kubectl run test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Test connectivity
kubectl run test --image=busybox --rm -it --restart=Never -- wget -O- my-service:80

# Check pod connectivity
kubectl exec my-pod -- ping other-pod-ip

# Debug pod
kubectl debug my-pod -it --image=busybox

# Check resource constraints
kubectl describe node my-node | grep -A 5 "Allocated resources"
```

---

## 📤 Output Formats

```bash
# Wide output (more columns)
kubectl get pods -o wide

# YAML output
kubectl get pod my-pod -o yaml

# JSON output
kubectl get pod my-pod -o json

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Just names
kubectl get pods -o name
```

---

## 🎨 Aliases & Shortcuts

```bash
# Add to ~/.bashrc or ~/.zshrc:
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgd='kubectl get deployments'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'

# Resource short names:
po = pods
svc = services
deploy = deployments
rs = replicasets
ns = namespaces
no = nodes
cm = configmaps
pv = persistentvolumes
pvc = persistentvolumeclaims
```

---

## 🔧 Useful Combinations

```bash
# Get pod names only
kubectl get pods -o name | cut -d'/' -f2

# Delete all evicted pods
kubectl get pods | grep Evicted | awk '{print $1}' | xargs kubectl delete pod

# Get container images
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].image}' | tr -s '[[:space:]]' '\n' | sort | uniq

# Count pods by status
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' | sort | uniq -c

# Find pods using most CPU
kubectl top pods --all-namespaces | sort --reverse --key 3 --numeric | head -10

# Get all images in cluster
kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c
```

---

## 📚 explain (Documentation)

```bash
# Explain resource
kubectl explain pods
kubectl explain services
kubectl explain deployments

# Explain specific field
kubectl explain pod.spec
kubectl explain deployment.spec.template
kubectl explain service.spec.type

# Recursive explain
kubectl explain deployment.spec --recursive
```

---

## 💡 Tips

1. **Use tab completion** - Makes life easier!
2. **Watch resources** - `kubectl get pods -w`
3. **Use labels** - Organize and filter resources
4. **Apply > Create** - `apply` is idempotent
5. **Use namespaces** - Separate environments
6. **Describe for details** - When `get` isn't enough
7. **Check events** - First step in troubleshooting
8. **Use --dry-run** - Preview changes

---

## 📚 Resources

- [kubectl Docs](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl Book](https://kubectl.docs.kubernetes.io/)

