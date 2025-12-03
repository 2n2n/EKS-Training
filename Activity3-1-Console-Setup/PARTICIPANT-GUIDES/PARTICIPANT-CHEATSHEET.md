# Participant Command Cheatsheet

Quick reference for all commands used in the workshop activities.

---

## 🔐 Authentication & Setup

```bash
# Configure AWS CLI
aws configure
# Enter: Access Key, Secret Key, Region (ap-southeast-1), Output (json)

# Verify AWS identity
aws sts get-caller-identity

# Configure kubectl for EKS
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

---

## 📁 Namespace Management

```bash
# CREATE namespace
kubectl create namespace <your-name>-workspace

# LIST namespaces
kubectl get namespaces
kubectl get ns

# SET default namespace
kubectl config set-context --current --namespace=<your-name>-workspace

# VIEW current namespace
kubectl config view --minify | grep namespace

# DESCRIBE namespace
kubectl describe namespace <name>

# DELETE namespace (CAREFUL - deletes everything inside!)
kubectl delete namespace <name>

# ALL namespaces flag
kubectl get pods --all-namespaces
kubectl get pods -A
```

---

## 🖥️ Node Management

```bash
# VIEW nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes

# LIST node groups
aws eks list-nodegroups \
    --cluster-name shared-workshop-cluster \
    --region ap-southeast-1

# DESCRIBE node group
aws eks describe-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <name> \
    --region ap-southeast-1

# CREATE node group
aws eks create-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <your-name>-nodes \
    --node-role arn:aws:iam::<account-id>:role/eks-workshop-node-role \
    --subnets <subnet-a> <subnet-b> \
    --instance-types t3.medium \
    --capacity-type SPOT \
    --scaling-config minSize=0,maxSize=2,desiredSize=1 \
    --region ap-southeast-1

# SCALE node group
aws eks update-nodegroup-config \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <name> \
    --scaling-config desiredSize=<n> \
    --region ap-southeast-1

# DELETE node group
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <your-name>-nodes \
    --region ap-southeast-1

# NODE operations
kubectl cordon <node-name>      # Mark unschedulable
kubectl uncordon <node-name>    # Allow scheduling
kubectl drain <node-name> --ignore-daemonsets  # Evict pods
kubectl label nodes <name> key=value           # Add label
kubectl label nodes <name> key-                # Remove label
kubectl taint nodes <name> key=value:NoSchedule      # Add taint
kubectl taint nodes <name> key=value:NoSchedule-     # Remove taint
```

---

## 🐳 ECR Image Management

```bash
# AUTHENTICATE Docker with ECR
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

# BUILD image
docker build -t <your-name>-<app>:<version> .

# TAG for ECR
docker tag <local-image>:<tag> \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps:<your-name>-<app>-<version>

# PUSH to ECR
docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps:<your-name>-<app>-<version>

# PULL from ECR
docker pull <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps:<tag>

# LIST images
aws ecr list-images --repository-name eks-workshop-apps --region ap-southeast-1

# DESCRIBE image
aws ecr describe-images \
    --repository-name eks-workshop-apps \
    --image-ids imageTag=<tag> \
    --region ap-southeast-1

# DELETE image (only yours!)
aws ecr batch-delete-image \
    --repository-name eks-workshop-apps \
    --image-ids imageTag=<your-tag> \
    --region ap-southeast-1
```

---

## 🚀 Deployment Management

```bash
# CREATE deployment (YAML)
kubectl apply -f deployment.yaml

# CREATE deployment (imperative)
kubectl create deployment <name> --image=<image> -n <namespace>

# VIEW deployments
kubectl get deployments -n <namespace>
kubectl describe deployment <name> -n <namespace>

# SCALE deployment
kubectl scale deployment <name> --replicas=<n> -n <namespace>

# UPDATE image
kubectl set image deployment/<name> <container>=<new-image> -n <namespace>

# ROLLOUT status
kubectl rollout status deployment/<name> -n <namespace>

# ROLLOUT history
kubectl rollout history deployment/<name> -n <namespace>

# ROLLBACK
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout undo deployment/<name> --to-revision=<n> -n <namespace>

# DELETE deployment
kubectl delete deployment <name> -n <namespace>
kubectl delete -f deployment.yaml
```

---

## 📦 Pod Management

```bash
# VIEW pods
kubectl get pods -n <namespace>
kubectl get pods -n <namespace> -o wide
kubectl get pods -A                    # All namespaces

# DESCRIBE pod
kubectl describe pod <name> -n <namespace>

# POD logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -f <pod-name> -n <namespace>           # Follow
kubectl logs <pod-name> --previous -n <namespace>   # Previous container
kubectl logs -l app=<label> -n <namespace>          # By label

# EXEC into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
kubectl exec <pod-name> -n <namespace> -- <command>

# DELETE pod
kubectl delete pod <name> -n <namespace>

# Resource usage
kubectl top pods -n <namespace>
```

---

## 🌐 Service Management

```bash
# CREATE service (expose deployment)
kubectl expose deployment <name> --type=NodePort --port=80 -n <namespace>

# VIEW services
kubectl get services -n <namespace>
kubectl get svc -n <namespace>
kubectl describe svc <name> -n <namespace>

# VIEW endpoints
kubectl get endpoints -n <namespace>

# PORT FORWARD (local access)
kubectl port-forward svc/<name> <local-port>:<svc-port> -n <namespace>

# DELETE service
kubectl delete svc <name> -n <namespace>
```

---

## 🔍 Debugging & Monitoring

```bash
# VIEW all resources
kubectl get all -n <namespace>

# EVENTS
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
kubectl get events -A --sort-by='.lastTimestamp'

# RESOURCE usage
kubectl top nodes
kubectl top pods -n <namespace>

# CLUSTER info
kubectl cluster-info
kubectl version
kubectl api-resources

# TEST connectivity from temp pod
kubectl run test-curl --image=curlimages/curl -it --rm -- curl <url>

# DEBUG pod
kubectl describe pod <name> -n <namespace>
kubectl logs <name> -n <namespace>
kubectl exec -it <name> -n <namespace> -- /bin/sh
```

---

## 🧹 Cleanup Commands

```bash
# DELETE all in namespace
kubectl delete all --all -n <namespace>

# DELETE specific resources
kubectl delete deployment <name> -n <namespace>
kubectl delete svc <name> -n <namespace>
kubectl delete pod <name> -n <namespace>

# DELETE namespace (and everything in it!)
kubectl delete namespace <your-name>-workspace

# DELETE node group
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name <your-name>-nodes \
    --region ap-southeast-1
```

---

## 📝 Common Patterns

### Quick Deploy and Expose

```bash
kubectl create deployment myapp --image=nginx:alpine -n $NS
kubectl expose deployment myapp --type=NodePort --port=80 -n $NS
kubectl get svc myapp -n $NS
```

### Watch Resources

```bash
kubectl get pods -n $NS -w           # Watch pods
kubectl get nodes -w                  # Watch nodes
kubectl rollout status deployment/<name> -n $NS  # Watch rollout
```

### Get External Access URL

```bash
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
NODE_PORT=$(kubectl get svc <svc-name> -n $NS -o jsonpath='{.spec.ports[0].nodePort}')
echo "http://$NODE_IP:$NODE_PORT"
```

### Environment Setup

```bash
# Set namespace variable
export NS=<your-name>-workspace

# Use in commands
kubectl get pods -n $NS
kubectl apply -f app.yaml -n $NS
```

---

## ⚠️ Safety Reminders

```bash
# ALWAYS specify namespace
kubectl delete pod xxx -n <namespace>  ✅
kubectl delete pod xxx                 ❌ (might delete from wrong namespace)

# NEVER delete system namespaces
kubectl delete namespace kube-system   ❌ NEVER!

# NEVER delete shared node group
aws eks delete-nodegroup ... --nodegroup-name training-nodes  ❌ NEVER!

# Always use YOUR name prefix
charles-workspace     ✅
charles-app           ✅
workspace             ❌
app                   ❌
```

---

## 🔗 Quick Links

- [Kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS CLI EKS Reference](https://docs.aws.amazon.com/cli/latest/reference/eks/)
- [AWS CLI ECR Reference](https://docs.aws.amazon.com/cli/latest/reference/ecr/)

