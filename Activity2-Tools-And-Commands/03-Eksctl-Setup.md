# eksctl Setup and Configuration

**Estimated Time: 10 minutes**

---

## 🎯 What You'll Do

1. Install eksctl (EKS command-line tool)
2. Verify installation
3. Learn basic usage
4. Test connectivity

---

## 📥 Installation

### macOS

**Method 1: Homebrew (Recommended)**

```bash
# Install eksctl:
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Verify:
eksctl version
```

**Method 2: Direct Download**

```bash
# Download and extract:
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# Move to PATH:
sudo mv /tmp/eksctl /usr/local/bin

# Verify:
eksctl version
```

### Linux

**Direct Download:**

```bash
# Download and extract:
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp

# Move to PATH:
sudo mv /tmp/eksctl /usr/local/bin

# Verify:
eksctl version
```

### Windows

**Method 1: Chocolatey (Recommended)**

```powershell
# Install eksctl:
choco install eksctl

# Verify:
eksctl version
```

**Method 2: Direct Download**

1. Download from: https://github.com/weaveworks/eksctl/releases
2. Choose: `eksctl_Windows_amd64.zip`
3. Extract to `C:\Program Files\eksctl\`
4. Add to PATH
5. Verify in Command Prompt:

```powershell
eksctl version
```

---

## ⚙️ Configuration

### AWS Credentials

eksctl uses AWS CLI credentials:

```bash
# eksctl will automatically use:
~/.aws/credentials  # Your AWS access keys
~/.aws/config       # Your default region

# Make sure AWS CLI is configured:
aws sts get-caller-identity
```

### Region Configuration

eksctl respects AWS CLI region:

```bash
# Check current region:
aws configure get region

# Or specify region in commands:
eksctl create cluster --region ap-southeast-1

# Or set environment variable:
export AWS_DEFAULT_REGION=ap-southeast-1
```

---

## ✅ Testing

### Verify Installation

```bash
# Check version:
eksctl version

# Expected output:
0.xxx.x
```

### Test Commands (No Resources Created)

```bash
# List clusters (should be empty):
eksctl get cluster

# Expected output:
No clusters found

# View help:
eksctl --help

# Command-specific help:
eksctl create cluster --help
eksctl delete cluster --help
```

### Test AWS Connectivity

```bash
# Check EKS service availability:
eksctl get cluster --region ap-southeast-1

# Should return empty list or work without errors
# If you get errors, check AWS CLI configuration
```

---

## 🔧 eksctl Features

### What eksctl Does

```
eksctl simplifies EKS cluster management:

Creates:
├── EKS Cluster
├── VPC with subnets
├── Security groups
├── IAM roles
├── Node groups
└── All via CloudFormation

Single command replaces:
├── 30+ AWS Console clicks
├── Multiple IAM role creations
├── VPC/subnet configuration
└── All the manual work!
```

### eksctl with Config Files

**Best practice: Use YAML config files**

```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-cluster
  region: ap-southeast-1

managedNodeGroups:
  - name: my-nodes
    instanceType: t3.medium
    minSize: 2
    maxSize: 2
    spot: true
```

```bash
# Create cluster from config:
eksctl create cluster -f cluster-config.yaml

# Much better than remembering flags!
```

---

## 💡 Pro Tips

### 1. Use Config Files

```bash
# ❌ Hard to remember:
eksctl create cluster \
  --name my-cluster \
  --region ap-southeast-1 \
  --nodegroup-name my-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --spot

# ✅ Easy with config file:
eksctl create cluster -f cluster-config.yaml
```

### 2. Dry Run

```bash
# Preview what will be created:
eksctl create cluster -f cluster-config.yaml --dry-run
```

### 3. Enable Logging

```bash
# See detailed output:
eksctl create cluster -f cluster-config.yaml --verbose 4
```

### 4. Update kubeconfig Automatically

```bash
# eksctl automatically runs:
aws eks update-kubeconfig --name cluster-name --region region

# So kubectl is configured automatically after cluster creation!
```

---

## 📋 Essential eksctl Commands (Preview)

You'll use these in Activity 3-5:

```bash
# Create cluster:
eksctl create cluster -f cluster-config.yaml

# List clusters:
eksctl get cluster

# Get cluster details:
eksctl get cluster --name my-cluster

# List node groups:
eksctl get nodegroup --cluster my-cluster

# Delete cluster (IMPORTANT for cleanup!):
eksctl delete cluster --name my-cluster

# Delete with confirmation skip:
eksctl delete cluster --name my-cluster --wait

# Get kubeconfig:
eksctl utils write-kubeconfig --cluster my-cluster
```

---

## 🚫 Common Issues

### Issue: "eksctl: command not found"

**Solution:**

```bash
# Find eksctl:
which eksctl

# If not found, add to PATH:
export PATH=$PATH:/usr/local/bin
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
```

### Issue: "Error: checking AWS STS access"

**Solution:**

```bash
# Check AWS CLI is configured:
aws sts get-caller-identity

# If not working, reconfigure:
aws configure
```

### Issue: "Error: unable to use kubectl with the EKS cluster"

**Solution:**

```bash
# Update kubeconfig manually:
aws eks update-kubeconfig --name your-cluster --region ap-southeast-1
```

### Issue: "Error: creating CloudFormation stack"

**Check:**
- IAM permissions sufficient?
- Region has capacity?
- Account limits reached?

**View CloudFormation events:**

```bash
# Find stack:
aws cloudformation list-stacks

# View events:
aws cloudformation describe-stack-events --stack-name eksctl-my-cluster-cluster
```

---

## 🎓 Understanding eksctl

### How eksctl Works

```
1. You run: eksctl create cluster -f config.yaml
   │
   ▼
2. eksctl reads config file
   │
   ▼
3. eksctl creates CloudFormation templates
   │
   ▼
4. CloudFormation creates:
   ├── VPC
   ├── Subnets
   ├── Security Groups
   ├── IAM Roles
   ├── EKS Cluster
   └── Node Group
   │
   ▼
5. eksctl configures kubectl
   │
   ▼
6. Cluster ready to use! ✅
```

### eksctl vs Manual Creation

| Aspect | Manual (Console/CLI) | eksctl |
|--------|---------------------|--------|
| **Time** | 60+ minutes | 20 minutes |
| **Complexity** | Very high | Low |
| **Reproducible** | No | Yes (config file) |
| **Cleanup** | Manual, tedious | One command |
| **Best Practice** | Must research | Built-in |
| **Learning** | Understand details | Quick start |

**Recommendation:**
- Activity 3: Manual (learn the details)
- Activity 4+: eksctl (production way)

---

## 🔍 eksctl Cluster Lifecycle

### Create

```bash
# Create cluster:
eksctl create cluster -f cluster-config.yaml

# Takes: 15-25 minutes
# Creates: Everything you need
```

### Manage

```bash
# List clusters:
eksctl get cluster

# Get details:
eksctl get cluster --name my-cluster -o yaml

# Scale node group:
eksctl scale nodegroup --cluster my-cluster --name my-nodes --nodes 5
```

### Update

```bash
# Update to new Kubernetes version:
eksctl upgrade cluster --name my-cluster --approve

# Update node group:
eksctl update nodegroup --cluster my-cluster --name my-nodes
```

### Delete

```bash
# Delete everything:
eksctl delete cluster --name my-cluster

# Takes: 10-15 minutes
# Deletes: All resources via CloudFormation
```

---

## ⚠️ Important Notes

### Cost Awareness

```bash
# Creating cluster starts billing:
eksctl create cluster ...
# ⏰ EKS Control Plane: $0.10/hour
# ⏰ EC2 Nodes: $0.0416+/hour per node
# 💰 Total: ~$3/day minimum

# Always delete when done!
eksctl delete cluster --name my-cluster
```

### Cluster Naming

```bash
# Use descriptive names:
✅ training-cluster
✅ dev-cluster
✅ john-test-cluster

# Avoid:
❌ cluster1
❌ test
❌ my-cluster
```

### Region Lock-in

```bash
# Cluster is tied to region:
--region ap-southeast-1

# Can't move cluster to different region
# Must delete and recreate
```

---

## ✅ Success Criteria

You're ready when:

- [ ] `eksctl version` shows recent version
- [ ] `eksctl get cluster` works (even if empty)
- [ ] AWS credentials are configured
- [ ] You understand eksctl basics

---

## 🚀 Next Steps

**All tools installed?**

Great! Now familiarize yourself with the cheatsheets:

1. **[04-AWS-CLI-Cheatsheet.md](04-AWS-CLI-Cheatsheet.md)**
2. **[05-Kubectl-Cheatsheet.md](05-Kubectl-Cheatsheet.md)**
3. **[06-Eksctl-Cheatsheet.md](06-Eksctl-Cheatsheet.md)**

**Then move to Activity 3:**

[../Activity3-Console-Setup/README.md](../Activity3-Console-Setup/README.md) - Create your first EKS cluster!

---

## 📖 Additional Resources

- [eksctl Documentation](https://eksctl.io/)
- [eksctl GitHub](https://github.com/weaveworks/eksctl)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- **Our cheatsheet:** [06-Eksctl-Cheatsheet.md](06-Eksctl-Cheatsheet.md)

