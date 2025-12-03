# kubectl Command Reference

Complete reference for kubectl commands used in this workshop.

---

## 📋 Table of Contents

- [Cluster & Configuration](#cluster--configuration)
- [Namespaces](#namespaces)
- [Nodes](#nodes)
- [Pods](#pods)
- [Deployments](#deployments)
- [Services](#services)
- [ConfigMaps & Secrets](#configmaps--secrets)
- [Events & Monitoring](#events--monitoring)
- [Utility Commands](#utility-commands)

---

## Cluster & Configuration

### Cluster Information

```bash
# Cluster info
kubectl cluster-info

# Cluster version (client and server)
kubectl version

# API resources available
kubectl api-resources

# API versions
kubectl api-versions
```

### Context Configuration

```bash
# View all contexts
kubectl config get-contexts

# View current context
kubectl config current-context

# Switch context
kubectl config use-context <context-name>

# View full config
kubectl config view

# View minified config (current context only)
kubectl config view --minify

# Set default namespace for context
kubectl config set-context --current --namespace=<namespace>

# Delete context
kubectl config delete-context <context-name>
```

---

## Namespaces

### View Namespaces

```bash
# List all namespaces
kubectl get namespaces
kubectl get ns

# Describe namespace
kubectl describe namespace <name>

# Get namespace with labels
kubectl get namespace <name> --show-labels
```

### Manage Namespaces

```bash
# Create namespace
kubectl create namespace <name>

# Create from YAML
kubectl apply -f namespace.yaml

# Delete namespace (DELETES EVERYTHING INSIDE!)
kubectl delete namespace <name>

# Add label to namespace
kubectl label namespace <name> key=value

# Remove label
kubectl label namespace <name> key-
```

---

## Nodes

### View Nodes

```bash
# List nodes
kubectl get nodes

# Wide output (more details)
kubectl get nodes -o wide

# Describe node
kubectl describe node <node-name>

# Node resource usage (requires metrics-server)
kubectl top nodes

# Get nodes with labels
kubectl get nodes --show-labels

# Filter nodes by label
kubectl get nodes -l <label-key>=<label-value>
```

### Manage Nodes

```bash
# Add label
kubectl label nodes <node-name> key=value

# Remove label
kubectl label nodes <node-name> key-

# Add taint
kubectl taint nodes <node-name> key=value:NoSchedule

# Other taint effects
kubectl taint nodes <node-name> key=value:NoExecute
kubectl taint nodes <node-name> key=value:PreferNoSchedule

# Remove taint
kubectl taint nodes <node-name> key=value:NoSchedule-

# Mark node unschedulable
kubectl cordon <node-name>

# Mark node schedulable
kubectl uncordon <node-name>

# Drain node (evict all pods)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

---

## Pods

### View Pods

```bash
# List pods in current namespace
kubectl get pods

# List pods in specific namespace
kubectl get pods -n <namespace>

# List pods in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Wide output
kubectl get pods -o wide

# Watch pods (live updates)
kubectl get pods -w

# Filter by label
kubectl get pods -l app=<label>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Get pod YAML
kubectl get pod <pod-name> -o yaml

# Get pod JSON
kubectl get pod <pod-name> -o json
```

### Pod Logs

```bash
# View logs
kubectl logs <pod-name> -n <namespace>

# Follow logs (streaming)
kubectl logs -f <pod-name> -n <namespace>

# Previous container logs (after restart)
kubectl logs <pod-name> --previous -n <namespace>

# Last N lines
kubectl logs <pod-name> --tail=100 -n <namespace>

# Since time
kubectl logs <pod-name> --since=1h -n <namespace>

# Logs from specific container (multi-container pod)
kubectl logs <pod-name> -c <container-name> -n <namespace>

# Logs from all pods with label
kubectl logs -l app=<label> -n <namespace>
```

### Execute in Pod

```bash
# Interactive shell
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Run single command
kubectl exec <pod-name> -n <namespace> -- <command>

# Examples
kubectl exec <pod-name> -n <namespace> -- ls /app
kubectl exec <pod-name> -n <namespace> -- cat /etc/hosts
kubectl exec <pod-name> -n <namespace> -- env

# Specific container
kubectl exec -it <pod-name> -c <container-name> -n <namespace> -- /bin/sh
```

### Manage Pods

```bash
# Create pod (imperative)
kubectl run <name> --image=<image>

# Create pod and execute
kubectl run <name> --image=<image> -it --rm -- <command>

# Delete pod
kubectl delete pod <pod-name> -n <namespace>

# Delete with grace period
kubectl delete pod <pod-name> --grace-period=0 --force

# Resource usage (requires metrics-server)
kubectl top pods -n <namespace>
```

---

## Deployments

### View Deployments

```bash
# List deployments
kubectl get deployments -n <namespace>
kubectl get deploy -n <namespace>

# Describe deployment
kubectl describe deployment <name> -n <namespace>

# Get deployment YAML
kubectl get deployment <name> -o yaml -n <namespace>
```

### Create & Update Deployments

```bash
# Create from YAML
kubectl apply -f deployment.yaml

# Create imperatively
kubectl create deployment <name> --image=<image> -n <namespace>

# Set replicas at creation
kubectl create deployment <name> --image=<image> --replicas=3

# Update image
kubectl set image deployment/<name> <container>=<new-image> -n <namespace>

# Edit deployment (opens editor)
kubectl edit deployment <name> -n <namespace>
```

### Scale Deployments

```bash
# Scale to specific replicas
kubectl scale deployment <name> --replicas=<n> -n <namespace>

# Scale multiple deployments
kubectl scale deployment <name1> <name2> --replicas=3

# Autoscale (HPA)
kubectl autoscale deployment <name> --min=2 --max=10 --cpu-percent=80
```

### Rollout Management

```bash
# Rollout status
kubectl rollout status deployment/<name> -n <namespace>

# Rollout history
kubectl rollout history deployment/<name> -n <namespace>

# Specific revision details
kubectl rollout history deployment/<name> --revision=<n>

# Rollback to previous
kubectl rollout undo deployment/<name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<name> --to-revision=<n> -n <namespace>

# Pause rollout
kubectl rollout pause deployment/<name>

# Resume rollout
kubectl rollout resume deployment/<name>

# Restart deployment (triggers new rollout)
kubectl rollout restart deployment/<name> -n <namespace>
```

### Delete Deployments

```bash
# Delete deployment
kubectl delete deployment <name> -n <namespace>

# Delete from YAML
kubectl delete -f deployment.yaml
```

---

## Services

### View Services

```bash
# List services
kubectl get services -n <namespace>
kubectl get svc -n <namespace>

# Describe service
kubectl describe service <name> -n <namespace>

# Get endpoints
kubectl get endpoints -n <namespace>
```

### Create Services

```bash
# Expose deployment
kubectl expose deployment <name> --type=ClusterIP --port=80 -n <namespace>
kubectl expose deployment <name> --type=NodePort --port=80 -n <namespace>
kubectl expose deployment <name> --type=LoadBalancer --port=80 -n <namespace>

# With target port
kubectl expose deployment <name> --type=NodePort --port=80 --target-port=8080

# Create from YAML
kubectl apply -f service.yaml
```

### Service Types

```bash
# ClusterIP (internal only)
--type=ClusterIP

# NodePort (external via node port)
--type=NodePort

# LoadBalancer (external via cloud LB)
--type=LoadBalancer
```

### Port Forward

```bash
# Forward to service
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n <namespace>

# Forward to pod
kubectl port-forward pod/<pod-name> <local-port>:<container-port> -n <namespace>

# Background
kubectl port-forward svc/<service-name> 8080:80 &
```

### Delete Services

```bash
# Delete service
kubectl delete service <name> -n <namespace>
kubectl delete svc <name> -n <namespace>
```

---

## ConfigMaps & Secrets

### ConfigMaps

```bash
# List configmaps
kubectl get configmaps -n <namespace>
kubectl get cm -n <namespace>

# Describe configmap
kubectl describe configmap <name> -n <namespace>

# Get configmap data
kubectl get configmap <name> -o yaml -n <namespace>

# Create from literal
kubectl create configmap <name> --from-literal=key=value

# Create from file
kubectl create configmap <name> --from-file=<filename>

# Delete configmap
kubectl delete configmap <name> -n <namespace>
```

### Secrets

```bash
# List secrets
kubectl get secrets -n <namespace>

# Describe secret
kubectl describe secret <name> -n <namespace>

# Get secret (encoded)
kubectl get secret <name> -o yaml -n <namespace>

# Decode secret value
kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 --decode

# Create from literal
kubectl create secret generic <name> --from-literal=key=value

# Create from file
kubectl create secret generic <name> --from-file=<filename>

# Delete secret
kubectl delete secret <name> -n <namespace>
```

---

## Events & Monitoring

### Events

```bash
# Get events in namespace
kubectl get events -n <namespace>

# Sort by time
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# All namespaces
kubectl get events -A --sort-by='.lastTimestamp'

# Watch events
kubectl get events -w -n <namespace>

# Filter by type
kubectl get events --field-selector type=Warning
```

### Resource Usage

```bash
# Node usage
kubectl top nodes

# Pod usage
kubectl top pods -n <namespace>

# Container usage
kubectl top pods --containers -n <namespace>

# Sort by CPU
kubectl top pods --sort-by=cpu

# Sort by memory
kubectl top pods --sort-by=memory
```

---

## Utility Commands

### Apply & Delete

```bash
# Apply configuration
kubectl apply -f <filename>
kubectl apply -f <directory>/

# Delete from file
kubectl delete -f <filename>

# Dry run (show what would happen)
kubectl apply -f <filename> --dry-run=client

# Generate YAML (don't apply)
kubectl create deployment test --image=nginx --dry-run=client -o yaml
```

### Get All Resources

```bash
# All resources in namespace
kubectl get all -n <namespace>

# All resources, all namespaces
kubectl get all -A

# Specific resource types
kubectl get pods,svc,deployments -n <namespace>
```

### Labels & Annotations

```bash
# Add label
kubectl label <resource-type> <name> key=value

# Remove label
kubectl label <resource-type> <name> key-

# Add annotation
kubectl annotate <resource-type> <name> key=value

# Remove annotation
kubectl annotate <resource-type> <name> key-
```

### Output Formats

```bash
# YAML output
kubectl get <resource> <name> -o yaml

# JSON output
kubectl get <resource> <name> -o json

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'

# Wide output
kubectl get pods -o wide
```

### Temporary Test Pod

```bash
# Run and delete after exit
kubectl run test --image=busybox -it --rm -- /bin/sh

# Curl test
kubectl run test-curl --image=curlimages/curl -it --rm -- curl <url>

# DNS test
kubectl run test-dns --image=busybox -it --rm -- nslookup kubernetes
```

---

## 📝 Common Patterns

### Quick Deploy Flow

```bash
kubectl create deployment myapp --image=nginx -n <ns>
kubectl expose deployment myapp --type=NodePort --port=80 -n <ns>
kubectl get svc myapp -n <ns>
```

### Debug Flow

```bash
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
kubectl exec -it <pod> -n <ns> -- /bin/sh
```

### Cleanup Flow

```bash
kubectl delete all --all -n <namespace>
kubectl delete namespace <namespace>
```

---

## 🔗 Additional Resources

- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl Reference Docs](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

