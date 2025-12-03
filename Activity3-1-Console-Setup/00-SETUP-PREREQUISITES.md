# Setup Prerequisites - For Participants

Before you can start working with the shared EKS cluster, you need to have the right tools installed and configured on your computer.

---

## 🎯 What You Need

This guide is for **participants** (not the root/admin). The root account will set up the cluster infrastructure first.

**Time to complete:** 30-45 minutes (first time)

---

## ✅ Checklist

Use this checklist to track your progress:

- [ ] AWS CLI installed and working
- [ ] kubectl installed and working  
- [ ] Docker installed and working (for building images)
- [ ] AWS credentials received from workshop admin
- [ ] AWS credentials configured locally
- [ ] Can connect to shared EKS cluster
- [ ] Text editor or IDE ready

---

## 📋 Required Tools

### 1. AWS CLI

The AWS Command Line Interface lets you interact with AWS services from your terminal.

**Why you need it:**
- Configure access to the EKS cluster
- Authenticate with ECR to push/pull images
- View AWS resources

#### Check if Already Installed

```bash
aws --version

# Expected output (version 2.x or higher):
# aws-cli/2.13.x Python/3.x.x ...
```

#### Install AWS CLI

**macOS:**
```bash
# Using Homebrew
brew install awscli

# Or download installer
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Windows:**
```powershell
# Download and run: https://awscli.amazonaws.com/AWSCLIV2.msi
# Or use chocolatey:
choco install awscli
```

#### Verify Installation

```bash
aws --version
# Should show version 2.x or higher
```

---

### 2. kubectl

kubectl is the Kubernetes command-line tool for running commands against Kubernetes clusters.

**Why you need it:**
- Deploy applications to the cluster
- View and manage pods, services, deployments
- Check cluster status and resources

#### Check if Already Installed

```bash
kubectl version --client

# Expected output:
# Client Version: v1.28.x or higher
```

#### Install kubectl

**macOS:**
```bash
# Using Homebrew
brew install kubectl

# Or download binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Linux:**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

**Windows:**
```powershell
# Using chocolatey:
choco install kubernetes-cli

# Or download: https://dl.k8s.io/release/v1.28.0/bin/windows/amd64/kubectl.exe
```

#### Verify Installation

```bash
kubectl version --client

# Should show version 1.24 or higher
```

---

### 3. Docker

Docker is needed to build container images for your applications.

**Why you need it:**
- Build Docker images locally
- Test images before pushing to ECR
- Understand containerization

#### Check if Already Installed

```bash
docker --version

# Expected output:
# Docker version 24.x.x or higher
```

#### Install Docker

**macOS:**
```bash
# Download Docker Desktop from:
# https://www.docker.com/products/docker-desktop

# Or using Homebrew:
brew install --cask docker

# Start Docker Desktop application
```

**Linux (Ubuntu/Debian):**
```bash
# Install Docker Engine
sudo apt-get update
sudo apt-get install docker.io

# Add your user to docker group (avoid sudo)
sudo usermod -aG docker $USER

# Log out and back in for group change to take effect
```

**Windows:**
```powershell
# Download Docker Desktop from:
# https://www.docker.com/products/docker-desktop

# Or using chocolatey:
choco install docker-desktop
```

#### Verify Installation

```bash
docker --version
# Should show version 20.x or higher

docker ps
# Should list running containers (may be empty - that's ok)
```

**Note:** If you get "permission denied" on Linux, run:
```bash
sudo usermod -aG docker $USER
# Then log out and log back in
```

---

### 4. Text Editor or IDE

You'll need a text editor to write YAML files and code.

**Recommended Options:**

**VS Code (Recommended):**
- Download: https://code.visualstudio.com/
- Install extensions:
  - Kubernetes (by Microsoft)
  - YAML (by Red Hat)
  - Docker (by Microsoft)

**Other Good Options:**
- Sublime Text
- Atom
- Vim/Nano (for terminal users)
- IntelliJ IDEA / PyCharm

---

## 🔑 AWS Credentials Setup

### Step 1: Get Credentials from Admin

The workshop admin will provide you with:

1. **IAM Username:** `eks-<yourname>` (e.g., `eks-charles`)
2. **Initial Password:** Temporary password
3. **AWS Account ID:** 12-digit number
4. **AWS Console URL:** https://`<account-id>`.signin.aws.amazon.com/console
5. **AWS Region:** ap-southeast-1 (Singapore)

### Step 2: Console Access (First Login)

1. Go to the AWS Console URL provided
2. Enter your IAM username: `eks-<yourname>`
3. Enter the temporary password
4. **You'll be forced to change password** - choose a strong one
5. Log in with new password

### Step 3: Create Access Keys

Access keys are needed for AWS CLI and kubectl.

1. In AWS Console, go to **IAM** service
2. Click **Users** in left menu
3. Click your username (`eks-<yourname>`)
4. Go to **Security credentials** tab
5. Scroll to **Access keys** section
6. Click **Create access key**
7. Choose **Command Line Interface (CLI)**
8. Check the confirmation box
9. Click **Next**, then **Create access key**
10. **Download the .csv file** or copy both keys:
    - Access Key ID (starts with AKIA...)
    - Secret Access Key (long random string)
11. **⚠️ Save these securely!** You can't see the secret key again

### Step 4: Configure AWS CLI

Configure your local AWS CLI with the credentials:

```bash
aws configure

# You'll be prompted for:
AWS Access Key ID [None]: <paste your access key ID>
AWS Secret Access Key [None]: <paste your secret access key>
Default region name [None]: ap-southeast-1
Default output format [None]: json
```

### Step 5: Verify AWS Credentials

```bash
# Check your identity
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "<account-id>",
#     "Arn": "arn:aws:iam::<account-id>:user/eks-<yourname>"
# }

# If this works, you're authenticated! ✅
```

---

## 🔌 Connect to EKS Cluster

The workshop admin will tell you when the cluster is ready. Once it is:

### Step 1: Get Cluster Name

The admin will provide:
- **Cluster Name:** (usually `shared-workshop-cluster`)
- **Region:** ap-southeast-1

### Step 2: Update kubeconfig

```bash
# Replace <cluster-name> with actual name
aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1

# Expected output:
# Added new context arn:aws:eks:ap-southeast-1:<account-id>:cluster/shared-workshop-cluster to ~/.kube/config
```

**What this does:**
- Downloads cluster certificate
- Adds cluster information to `~/.kube/config`
- Sets up authentication
- Makes this cluster your current context

### Step 3: Verify Cluster Connection

```bash
# Test connection
kubectl get nodes

# Expected output (2 nodes):
# NAME                                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-xxx.ap-southeast-1.compute.internal Ready    <none>   5m    v1.28.x
# ip-10-0-2-xxx.ap-southeast-1.compute.internal Ready    <none>   5m    v1.28.x

# If you see 2 nodes with STATUS=Ready, you're connected! ✅
```

### Step 4: Check Your Permissions

```bash
# View all namespaces (tests read permission)
kubectl get namespaces

# Try to view system pods (tests admin permission)
kubectl get pods -n kube-system

# If both work, you have full cluster access! ✅
```

---

## 🚨 Troubleshooting

### Issue: "aws: command not found"

**Solution:**
```bash
# Check if AWS CLI is in your PATH
which aws

# If not found, reinstall AWS CLI or add to PATH:
export PATH=$PATH:/usr/local/bin
```

### Issue: "kubectl: command not found"

**Solution:**
```bash
# Check if kubectl is in your PATH
which kubectl

# If not found, reinstall kubectl or add to PATH
export PATH=$PATH:/usr/local/bin
```

### Issue: "Unable to connect to the server"

**Solution:**
```bash
# Check AWS credentials are configured
aws sts get-caller-identity

# Re-run update-kubeconfig
aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1

# Check cluster exists
aws eks describe-cluster --name shared-workshop-cluster --region ap-southeast-1
```

### Issue: "error: You must be logged in to the server (Unauthorized)"

**Possible causes:**
1. AWS credentials not configured correctly
2. Your IAM user not added to cluster access (ask admin)
3. Wrong AWS region

**Solution:**
```bash
# Verify you're using correct credentials
aws sts get-caller-identity

# Verify region
aws configure get region
# Should show: ap-southeast-1

# Ask admin to check aws-auth ConfigMap includes your user
```

### Issue: Docker permission denied

**Linux users:**
```bash
# Add yourself to docker group
sudo usermod -aG docker $USER

# Log out and log back in
# Or run: newgrp docker

# Test
docker ps
```

---

## 📁 Recommended Directory Structure

Create a workspace for your workshop files:

```bash
# Create workshop directory
mkdir -p ~/eks-workshop
cd ~/eks-workshop

# Create subdirectories
mkdir -p manifests      # Kubernetes YAML files
mkdir -p docker         # Dockerfiles and app code  
mkdir -p scripts        # Helper scripts

# Directory structure:
# eks-workshop/
# ├── manifests/       (deployment.yaml, service.yaml, etc.)
# ├── docker/          (Dockerfile, app source code)
# └── scripts/         (helper scripts)
```

---

## 🎓 Optional: Learn the Basics

If you're new to these tools, spend 15-30 minutes familiarizing yourself:

### AWS CLI Basics
```bash
# Get help
aws help
aws eks help

# List EKS clusters
aws eks list-clusters --region ap-southeast-1

# Describe a cluster
aws eks describe-cluster --name <cluster-name> --region ap-southeast-1
```

### kubectl Basics
```bash
# Get help
kubectl help
kubectl get --help

# View resources
kubectl get nodes
kubectl get pods
kubectl get services

# Get detailed information
kubectl describe node <node-name>
```

### Docker Basics
```bash
# Get help
docker --help

# List images
docker images

# List running containers
docker ps

# Pull a test image
docker pull nginx:alpine

# Run a test container
docker run -d -p 8080:80 nginx:alpine

# Visit http://localhost:8080 in browser
# Stop the container:
docker ps  # Get container ID
docker stop <container-id>
```

---

## ✅ Final Checklist

Before proceeding to participant guides, ensure:

- [ ] AWS CLI version 2.x installed
- [ ] kubectl version 1.24+ installed
- [ ] Docker installed and working
- [ ] AWS credentials configured (`aws sts get-caller-identity` works)
- [ ] Can connect to EKS cluster (`kubectl get nodes` shows 2 nodes)
- [ ] Can view cluster resources (`kubectl get namespaces` works)
- [ ] Have a text editor ready
- [ ] Created a workspace directory

---

## 🚀 What's Next?

Once all prerequisites are complete:

1. **Read:** [SAFETY-GUIDELINES.md](SAFETY-GUIDELINES.md) ⚠️ **IMPORTANT!**
2. **Start:** [PARTICIPANT-GUIDES/01-CONNECT-TO-CLUSTER.md](PARTICIPANT-GUIDES/01-CONNECT-TO-CLUSTER.md)
3. **Learn:** Create your first namespace and deploy an application!

---

## 📚 Additional Resources

**AWS CLI Documentation:**
- Official docs: https://docs.aws.amazon.com/cli/
- EKS commands: https://docs.aws.amazon.com/cli/latest/reference/eks/

**kubectl Documentation:**
- Official docs: https://kubernetes.io/docs/reference/kubectl/
- Cheat sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

**Docker Documentation:**
- Official docs: https://docs.docker.com/
- Get started: https://docs.docker.com/get-started/

**Activity 2 Reference:**
- Tool setup guides: ../Activity2-Tools-And-Commands/
- Command cheatsheets in Activity 2

---

**You're ready to start!** Once prerequisites are complete, move to the participant guides. 🎉

