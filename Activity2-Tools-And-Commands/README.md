# Activity 2: Tools and Commands Setup

Welcome to Activity 2! Now that you understand the concepts, let's get your machine ready for hands-on work with EKS.

---

## 🎯 Learning Objectives

By the end of this activity, you will have:

- ✅ AWS CLI installed and configured
- ✅ kubectl installed and verified
- ✅ eksctl installed and ready
- ✅ Quick reference cheatsheets for all tools
- ✅ Your AWS credentials configured
- ✅ Verification that everything works

---

## ⏱️ Time Estimate

**Total Time: 30-60 minutes**

This is setup time - no AWS costs incurred!

| Document | Topic | Time |
|----------|-------|------|
| 01 | AWS CLI Setup | 15 min |
| 02 | kubectl Setup | 10 min |
| 03 | eksctl Setup | 10 min |
| 04 | AWS CLI Cheatsheet | Reference |
| 05 | kubectl Cheatsheet | Reference |
| 06 | eksctl Cheatsheet | Reference |

**Note:** Setup time varies by operating system and internet speed.

---

## 📋 Prerequisites

Before starting, you need:

### Required

- [ ] **AWS Account** with administrator access
- [ ] **IAM User** with programmatic access (Access Key + Secret Key)
- [ ] **Computer** with admin rights (to install software)
- [ ] **Internet connection** (to download tools)

### Optional but Recommended

- [ ] **Code editor** (VS Code, Sublime, etc.)
- [ ] **Terminal** you're comfortable with (iTerm2, Windows Terminal, etc.)
- [ ] **Homebrew** (macOS) or **Chocolatey** (Windows) for easier installation

---

## 🔧 Tools We'll Install

### 1. AWS CLI (Command Line Interface)

**What:** Command-line tool to manage AWS services

```bash
# You'll use it for:
aws eks describe-cluster --name my-cluster
aws ec2 describe-instances
aws iam list-roles
```

**Why:** Interact with AWS from terminal

### 2. kubectl (Kubernetes Command-Line Tool)

**What:** Command-line tool to manage Kubernetes clusters

```bash
# You'll use it for:
kubectl get pods
kubectl apply -f deployment.yaml
kubectl logs my-pod
```

**Why:** Control your EKS cluster and deploy applications

### 3. eksctl (EKS Command-Line Tool)

**What:** Simplified tool to create and manage EKS clusters

```bash
# You'll use it for:
eksctl create cluster -f cluster-config.yaml
eksctl delete cluster --name my-cluster
eksctl get clusters
```

**Why:** Easiest way to create EKS clusters

---

## 📚 Installation Guides

### Start Here

1. **[01-AWS-CLI-Setup.md](01-AWS-CLI-Setup.md)** - Install and configure AWS CLI
   - Installation for macOS, Linux, Windows
   - Configure with your AWS credentials
   - Test connection

2. **[02-Kubectl-Setup.md](02-Kubectl-Setup.md)** - Install kubectl
   - Installation for all platforms
   - Verify installation
   - Learn basic commands

3. **[03-Eksctl-Setup.md](03-Eksctl-Setup.md)** - Install eksctl
   - Installation for all platforms
   - Verify installation
   - Test basic functionality

### Cheatsheets (Keep Handy!)

4. **[04-AWS-CLI-Cheatsheet.md](04-AWS-CLI-Cheatsheet.md)** - Common AWS CLI commands
   - EC2 commands
   - EKS commands
   - VPC commands
   - IAM commands

5. **[05-Kubectl-Cheatsheet.md](05-Kubectl-Cheatsheet.md)** - Essential kubectl commands
   - Get resources
   - Create/update resources
   - Debug and troubleshoot
   - Logs and exec

6. **[06-Eksctl-Cheatsheet.md](06-Eksctl-Cheatsheet.md)** - eksctl command reference
   - Cluster management
   - Node group operations
   - Configuration files

---

## 💻 Operating System Specific Notes

### macOS Users

**Recommended method:** Use Homebrew

```bash
# Install Homebrew first (if not installed):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then install tools:
brew install awscli
brew install kubectl
brew install eksctl
```

**Pros:**
- ✅ Easy to install
- ✅ Easy to update
- ✅ Manages dependencies

### Linux Users

**Methods vary by distribution:**

```bash
# Ubuntu/Debian: apt
sudo apt-get install awscli

# Red Hat/CentOS: yum
sudo yum install awscli

# Or use official binaries (recommended for kubectl/eksctl)
```

**Pros:**
- ✅ Native package managers
- ✅ System-wide installation

### Windows Users

**Recommended method:** Use official installers or Chocolatey

```powershell
# Option 1: Chocolatey
choco install awscli
choco install kubernetes-cli
choco install eksctl

# Option 2: Official installers
# Download from official websites
```

**Pros:**
- ✅ GUI installers available
- ✅ Windows Terminal integration

---

## ✅ Verification Checklist

After installation, verify everything works:

```bash
# 1. AWS CLI
aws --version
# Should output: aws-cli/2.x.x ...

aws sts get-caller-identity
# Should output your AWS account info

# 2. kubectl
kubectl version --client
# Should output: Client Version: v1.28.x ...

# 3. eksctl
eksctl version
# Should output: 0.x.x
```

### Success Criteria

You're ready to proceed when:

- [ ] `aws --version` shows version 2.x or higher
- [ ] `aws sts get-caller-identity` returns your AWS account
- [ ] `kubectl version --client` shows version 1.27+ or higher
- [ ] `eksctl version` shows recent version
- [ ] No error messages from any command

---

## 🚫 Common Issues and Solutions

### Issue: "Command not found"

**Cause:** Tool not in PATH

**Solution:**
```bash
# Find where tool is installed
which aws
which kubectl
which eksctl

# Add to PATH (example for bash):
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Issue: "Access Denied" (AWS CLI)

**Cause:** Credentials not configured or insufficient permissions

**Solution:**
```bash
# Reconfigure AWS CLI
aws configure

# Enter:
# - Access Key ID
# - Secret Access Key
# - Region: ap-southeast-1
# - Output format: json

# Test again:
aws sts get-caller-identity
```

### Issue: kubectl connects to wrong cluster

**Cause:** Multiple kubeconfig files or contexts

**Solution:**
```bash
# Check current context
kubectl config current-context

# View all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>
```

---

## 💡 Pro Tips

### 1. Use Command Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgn='kubectl get nodes'

# Now you can use:
k get pods  # instead of kubectl get pods
```

### 2. Enable Autocompletion

```bash
# kubectl autocompletion (bash)
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

# kubectl autocompletion (zsh)
source <(kubectl completion zsh)
echo "source <(kubectl completion zsh)" >> ~/.zshrc
```

### 3. Use kubectl plugins

```bash
# Install krew (kubectl plugin manager)
kubectl krew install ctx  # Switch contexts easily
kubectl krew install ns   # Switch namespaces easily
```

### 4. Keep Tools Updated

```bash
# macOS (Homebrew):
brew upgrade awscli kubectl eksctl

# Linux:
# Check your package manager

# Windows (Chocolatey):
choco upgrade awscli kubernetes-cli eksctl
```

---

## 📖 What Each Tool Does

### AWS CLI - AWS Management

```
Use AWS CLI when you need to:
✅ View AWS resources (EC2, VPC, etc.)
✅ Check cluster status (aws eks describe-cluster)
✅ Manage IAM roles/policies
✅ Troubleshoot AWS-level issues
✅ Automate AWS tasks

You won't use it for:
❌ Deploying pods/services (use kubectl)
❌ Daily Kubernetes operations (use kubectl)
```

### kubectl - Kubernetes Management

```
Use kubectl when you need to:
✅ Deploy applications (kubectl apply)
✅ View pods, services, deployments
✅ Check logs (kubectl logs)
✅ Debug applications (kubectl exec)
✅ Scale applications (kubectl scale)
✅ Daily Kubernetes operations

You won't use it for:
❌ Creating the cluster (use eksctl)
❌ AWS-specific tasks (use aws cli)
```

### eksctl - EKS Cluster Management

```
Use eksctl when you need to:
✅ Create EKS clusters
✅ Delete EKS clusters
✅ Manage node groups
✅ Update cluster configurations
✅ Quick cluster operations

You won't use it for:
❌ Deploying applications (use kubectl)
❌ Daily operations (use kubectl)
❌ After cluster is created (mostly kubectl)
```

---

## 🎓 Learning Path

### During Installation

While tools are installing:

1. Read the cheatsheets
2. Familiarize yourself with command syntax
3. Bookmark official documentation
4. Set up your terminal for comfort

### After Installation

1. Run verification commands
2. Practice basic commands from cheatsheets
3. Configure your shell (aliases, completion)
4. Move to Activity 3 (hands-on!)

---

## 📚 Additional Resources

### Official Documentation

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [eksctl Documentation](https://eksctl.io/)

### Interactive Learning

- [AWS CLI Interactive Tutorial](https://aws.amazon.com/cli/)
- [Kubernetes Interactive Tutorials](https://kubernetes.io/docs/tutorials/)

### Community

- AWS Forums
- Kubernetes Slack
- Stack Overflow

---

## 🚀 Next Steps

Once all tools are installed and verified:

**Move to Activity 3:** [../Activity3-Console-Setup/README.md](../Activity3-Console-Setup/README.md)

You'll create your first EKS cluster using the AWS Console (the long way) to understand what's happening behind the scenes!

---

## 💰 Cost Note

**Activity 2 costs: $0**

You're only installing tools on your local machine. No AWS resources are created yet!

Starting with Activity 3, you'll create AWS resources that incur costs (~$3/day).

---

**Ready to install?** Start with [01-AWS-CLI-Setup.md](01-AWS-CLI-Setup.md)!

**Questions or issues?** Check the troubleshooting section in each installation guide.

**Already have tools installed?** Jump straight to the cheatsheets for quick reference!

