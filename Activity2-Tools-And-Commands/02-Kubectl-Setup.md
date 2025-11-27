# kubectl Setup and Configuration

**Estimated Time: 10 minutes**

---

## 🎯 What You'll Do

1. Install kubectl (Kubernetes command-line tool)
2. Verify installation
3. Learn basic configuration
4. Test commands

---

## 📥 Installation

### macOS

**Method 1: Homebrew (Recommended)**

```bash
# Install kubectl:
brew install kubectl

# Verify:
kubectl version --client
```

**Method 2: Direct Download**

```bash
# Download latest:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"

# Make executable:
chmod +x ./kubectl

# Move to PATH:
sudo mv ./kubectl /usr/local/bin/kubectl

# Verify:
kubectl version --client
```

### Linux

**Method 1: Package Manager**

```bash
# Ubuntu/Debian:
sudo apt-get update
sudo apt-get install -y kubectl

# Or snap:
sudo snap install kubectl --classic
```

**Method 2: Direct Download**

```bash
# Download latest:
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make executable:
chmod +x ./kubectl

# Move to PATH:
sudo mv ./kubectl /usr/local/bin/kubectl

# Verify:
kubectl version --client
```

### Windows

**Method 1: Chocolatey**

```powershell
# Install kubectl:
choco install kubernetes-cli

# Verify:
kubectl version --client
```

**Method 2: Direct Download**

1. Download from: https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe
2. Add to PATH:
   - Move kubectl.exe to `C:\Program Files\kubectl\`
   - Add `C:\Program Files\kubectl\` to system PATH
3. Verify in Command Prompt:

```powershell
kubectl version --client
```

---

## ⚙️ Configuration

### kubeconfig File

kubectl uses a config file to connect to clusters:

```bash
# Default location:
~/.kube/config  (Linux/macOS)
C:\Users\USERNAME\.kube\config  (Windows)
```

**Note:** You don't have a cluster yet, so this file won't exist or will be empty. That's fine!

### After EKS Cluster Creation

When you create an EKS cluster, you'll run:

```bash
aws eks update-kubeconfig --name your-cluster-name --region ap-southeast-1
```

This automatically:
- Downloads cluster credentials
- Updates `~/.kube/config`
- Sets up connection to cluster

---

## ✅ Testing (Without Cluster)

### Verify Installation

```bash
# Check version:
kubectl version --client

# Expected output:
Client Version: v1.28.x
Kustomize Version: v5.x.x
```

### Test Commands (Will Fail - That's OK!)

```bash
# Try to get nodes:
kubectl get nodes

# Expected error (no cluster yet):
The connection to the server localhost:8080 was refused
# This is normal! You don't have a cluster yet.
```

### View Help

```bash
# General help:
kubectl help

# Command-specific help:
kubectl get --help
kubectl create --help
kubectl apply --help
```

---

## 🔧 Advanced Configuration

### Multiple Clusters (kubeconfig contexts)

When you have multiple clusters:

```bash
# View current context:
kubectl config current-context

# List all contexts:
kubectl config get-contexts

# Switch context:
kubectl config use-context my-cluster

# View full config:
kubectl config view
```

**Example kubeconfig:**

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://xxxxx.eks.ap-southeast-1.amazonaws.com
    certificate-authority-data: LS0t...
  name: training-cluster.ap-southeast-1.eksctl.io
contexts:
- context:
    cluster: training-cluster.ap-southeast-1.eksctl.io
    user: your-user@training-cluster.ap-southeast-1.eksctl.io
  name: training-cluster
current-context: training-cluster
users:
- name: your-user@training-cluster.ap-southeast-1.eksctl.io
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
      - eks
      - get-token
      - --cluster-name
      - training-cluster
```

### Custom kubeconfig Location

```bash
# Use different kubeconfig:
kubectl --kubeconfig=/path/to/config get pods

# Or set environment variable:
export KUBECONFIG=/path/to/config
kubectl get pods
```

---

## 💡 Pro Tips

### 1. Enable Shell Completion

**Bash:**

```bash
# Add to ~/.bashrc:
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

**Zsh:**

```bash
# Add to ~/.zshrc:
source <(kubectl completion zsh)
echo "source <(kubectl completion zsh)" >> ~/.zshrc
```

**Effect:**
- Tab completion for commands
- Tab completion for resource names
- Much faster workflow!

### 2. Create Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc:
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Usage:
k get pods  # instead of kubectl get pods
kgp  # list pods
kl my-pod  # view logs
```

### 3. Set Default Namespace

```bash
# Set default namespace (avoid typing -n every time):
kubectl config set-context --current --namespace=my-namespace

# Now all commands use that namespace:
kubectl get pods  # uses my-namespace
```

### 4. Use kubectl explain

```bash
# Learn about resources:
kubectl explain pod
kubectl explain deployment
kubectl explain service

# Dive deeper:
kubectl explain pod.spec
kubectl explain deployment.spec.template
```

---

## 📋 Essential kubectl Commands (Preview)

You'll use these once you have a cluster:

```bash
# View resources:
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get nodes

# Create resources:
kubectl create deployment nginx --image=nginx
kubectl apply -f deployment.yaml

# View details:
kubectl describe pod my-pod
kubectl describe node my-node

# Logs and debugging:
kubectl logs my-pod
kubectl logs -f my-pod  # follow logs
kubectl exec -it my-pod -- bash  # shell into container

# Update resources:
kubectl edit deployment my-app
kubectl scale deployment my-app --replicas=5

# Delete resources:
kubectl delete pod my-pod
kubectl delete deployment my-app
```

---

## 🚫 Common Issues

### Issue: "kubectl: command not found"

**Solution:**

```bash
# Find kubectl:
which kubectl

# If not found, reinstall or add to PATH:
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
```

### Issue: "The connection to the server localhost:8080 was refused"

**This is normal before cluster creation!**

After creating cluster, run:

```bash
aws eks update-kubeconfig --name your-cluster-name --region ap-southeast-1
```

### Issue: "error: You must be logged in to the server"

**Solution:**

```bash
# Update kubeconfig:
aws eks update-kubeconfig --name your-cluster-name --region ap-southeast-1

# Check current context:
kubectl config current-context

# If wrong context:
kubectl config use-context correct-context-name
```

### Issue: Permission denied errors

**Solution:**

```bash
# Check file permissions:
ls -la ~/.kube/config

# Fix if needed:
chmod 600 ~/.kube/config
```

---

## 🎓 Learning kubectl

### Command Structure

```bash
kubectl [command] [type] [name] [flags]

Examples:
kubectl get pods
kubectl get pod my-pod
kubectl describe deployment my-app
kubectl delete service my-service
kubectl logs pod/my-pod
```

### Resource Types (Short Names)

```bash
# Full name → Short name:
pods → po
services → svc
deployments → deploy
replicasets → rs
namespaces → ns
nodes → no
configmaps → cm
secrets → secret

# Use short names:
kubectl get po  # same as kubectl get pods
kubectl get svc  # same as kubectl get services
```

### Output Formats

```bash
# Wide output (more columns):
kubectl get pods -o wide

# YAML:
kubectl get pod my-pod -o yaml

# JSON:
kubectl get pod my-pod -o json

# Custom columns:
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Just names:
kubectl get pods -o name
```

---

## ✅ Success Criteria

You're ready when:

- [ ] `kubectl version --client` shows v1.27+
- [ ] You understand kubectl will fail without a cluster (normal!)
- [ ] Shell completion is set up (optional but helpful)
- [ ] You've reviewed basic commands

---

## 🚀 Next Steps

**kubectl installed and tested?**

Move to: [03-Eksctl-Setup.md](03-Eksctl-Setup.md)

---

## 📖 Additional Resources

- [kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl Book](https://kubectl.docs.kubernetes.io/)
- **Our cheatsheet:** [05-Kubectl-Cheatsheet.md](05-Kubectl-Cheatsheet.md)

