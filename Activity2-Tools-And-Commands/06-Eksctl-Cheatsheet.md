# eksctl Cheatsheet

Quick reference for eksctl - the official CLI tool for creating and managing EKS clusters.

---

## 🎯 Cluster Management

### Create Cluster

```bash
# Simple cluster (defaults)
eksctl create cluster

# With custom name and region
eksctl create cluster --name my-cluster --region ap-southeast-1

# From config file (RECOMMENDED)
eksctl create cluster -f cluster-config.yaml

# With specific parameters
eksctl create cluster \
  --name my-cluster \
  --region ap-southeast-1 \
  --nodegroup-name my-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4

# With Spot instances
eksctl create cluster \
  --name my-cluster \
  --region ap-southeast-1 \
  --nodegroup-name my-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --spot

# Dry run (see what will be created)
eksctl create cluster -f cluster-config.yaml --dry-run
```

### List Clusters

```bash
# List all clusters
eksctl get cluster

# List in specific region
eksctl get cluster --region ap-southeast-1

# Get specific cluster
eksctl get cluster --name my-cluster

# Detailed output
eksctl get cluster --name my-cluster -o yaml
eksctl get cluster --name my-cluster -o json
```

### Delete Cluster

```bash
# Delete cluster
eksctl delete cluster --name my-cluster

# Delete with region
eksctl delete cluster --name my-cluster --region ap-southeast-1

# Wait for deletion to complete
eksctl delete cluster --name my-cluster --wait

# Disable confirmation prompt
eksctl delete cluster --name my-cluster --disable-nodegroup-eviction
```

### Update Cluster

```bash
# Update cluster version
eksctl upgrade cluster --name my-cluster --approve

# Update cluster configuration
eksctl update cluster -f cluster-config.yaml --approve
```

---

## 🖥️ Node Group Management

### Create Node Group

```bash
# Add new node group
eksctl create nodegroup \
  --cluster my-cluster \
  --name new-nodes \
  --node-type t3.large \
  --nodes 3

# From config file
eksctl create nodegroup -f nodegroup-config.yaml

# With Spot instances
eksctl create nodegroup \
  --cluster my-cluster \
  --name spot-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --spot
```

### List Node Groups

```bash
# List node groups
eksctl get nodegroup --cluster my-cluster

# Detailed output
eksctl get nodegroup --cluster my-cluster -o yaml
```

### Scale Node Group

```bash
# Scale node group
eksctl scale nodegroup \
  --cluster my-cluster \
  --name my-nodes \
  --nodes 5

# Set min and max
eksctl scale nodegroup \
  --cluster my-cluster \
  --name my-nodes \
  --nodes-min 2 \
  --nodes-max 10
```

### Delete Node Group

```bash
# Delete node group
eksctl delete nodegroup \
  --cluster my-cluster \
  --name my-nodes

# Wait for deletion
eksctl delete nodegroup \
  --cluster my-cluster \
  --name my-nodes \
  --wait

# Drain nodes before deleting
eksctl delete nodegroup \
  --cluster my-cluster \
  --name my-nodes \
  --drain
```

### Update Node Group

```bash
# Update node group version
eksctl upgrade nodegroup \
  --cluster my-cluster \
  --name my-nodes

# Update with config file
eksctl update nodegroup -f nodegroup-config.yaml
```

---

## ⚙️ IAM & IRSA

### IAM Service Accounts

```bash
# Create IAM service account
eksctl create iamserviceaccount \
  --cluster my-cluster \
  --name my-service-account \
  --namespace default \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
  --approve

# List IAM service accounts
eksctl get iamserviceaccount --cluster my-cluster

# Delete IAM service account
eksctl delete iamserviceaccount \
  --cluster my-cluster \
  --name my-service-account \
  --namespace default
```

### IAM Identity Mappings

```bash
# Create IAM identity mapping
eksctl create iamidentitymapping \
  --cluster my-cluster \
  --arn arn:aws:iam::123456789012:user/admin \
  --username admin \
  --group system:masters

# List IAM identity mappings
eksctl get iamidentitymapping --cluster my-cluster

# Delete IAM identity mapping
eksctl delete iamidentitymapping \
  --cluster my-cluster \
  --arn arn:aws:iam::123456789012:user/admin
```

---

## 🔧 Utils & Configuration

### Kubeconfig

```bash
# Write kubeconfig
eksctl utils write-kubeconfig --cluster my-cluster

# Write to specific file
eksctl utils write-kubeconfig \
  --cluster my-cluster \
  --kubeconfig ~/.kube/my-cluster-config

# Set as current context
eksctl utils write-kubeconfig \
  --cluster my-cluster \
  --set-kubeconfig-context
```

### Describe Cluster

```bash
# Describe all cluster stacks
eksctl utils describe-stacks --cluster my-cluster

# Describe specific stack
eksctl utils describe-stacks \
  --cluster my-cluster \
  --stack eksctl-my-cluster-cluster
```

### Update AWS Auth ConfigMap

```bash
# Update aws-auth configmap
eksctl utils update-authentication-mode \
  --cluster my-cluster \
  --authentication-mode API_AND_CONFIG_MAP
```

---

## 📦 Addons

### List Addons

```bash
# List installed addons
eksctl get addon --cluster my-cluster

# List available addons
eksctl utils describe-addon-versions --kubernetes-version 1.28
```

### Install Addons

```bash
# Install addon
eksctl create addon \
  --cluster my-cluster \
  --name vpc-cni

# Install specific version
eksctl create addon \
  --cluster my-cluster \
  --name vpc-cni \
  --version v1.15.0

# Install with service account
eksctl create addon \
  --cluster my-cluster \
  --name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::123456789012:role/EBS_CSI_DriverRole
```

### Update Addons

```bash
# Update addon
eksctl update addon \
  --cluster my-cluster \
  --name vpc-cni

# Update to specific version
eksctl update addon \
  --cluster my-cluster \
  --name vpc-cni \
  --version v1.16.0
```

### Delete Addons

```bash
# Delete addon
eksctl delete addon \
  --cluster my-cluster \
  --name vpc-cni
```

---

## 🌐 Networking

### Enable Pod Identity

```bash
# Associate IAM OIDC provider
eksctl utils associate-iam-oidc-provider \
  --cluster my-cluster \
  --approve
```

---

## 📝 Config File Examples

### Basic Cluster Config

```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-cluster
  region: ap-southeast-1
  version: "1.28"

managedNodeGroups:
  - name: my-nodes
    instanceType: t3.medium
    minSize: 2
    maxSize: 4
    desiredCapacity: 2
    spot: true
    volumeSize: 20
    volumeType: gp3
    labels:
      role: worker
    tags:
      Environment: development
```

### Advanced Cluster Config

```yaml
# advanced-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: my-cluster
  region: ap-southeast-1
  version: "1.28"

vpc:
  cidr: 10.0.0.0/16
  nat:
    gateway: Disable  # Use public subnets only

managedNodeGroups:
  - name: on-demand-nodes
    instanceType: t3.medium
    minSize: 2
    maxSize: 2
    desiredCapacity: 2
    privateNetworking: false
    spot: false
    volumeSize: 20
    volumeType: gp3
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        ebs: true
        cloudWatch: true

  - name: spot-nodes
    instanceType: t3.medium
    minSize: 1
    maxSize: 5
    desiredCapacity: 2
    spot: true
    privateNetworking: false
    taints:
    - key: workload
      value: batch
      effect: NoSchedule

cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit", "authenticator"]
    logRetentionInDays: 7
```

---

## 🔍 Troubleshooting

### View Logs

```bash
# Enable verbose output
eksctl create cluster -f config.yaml --verbose 4

# View CloudFormation events
aws cloudformation describe-stack-events \
  --stack-name eksctl-my-cluster-cluster

# Check cluster status
eksctl get cluster --name my-cluster -o yaml
```

### Common Issues

```bash
# Issue: Cluster creation fails
# Check CloudFormation:
eksctl utils describe-stacks --cluster my-cluster

# Issue: Nodes not joining
# Check node group:
eksctl get nodegroup --cluster my-cluster

# Issue: Permission denied
# Check AWS credentials:
aws sts get-caller-identity
```

---

## 💡 Best Practices

### 1. Use Config Files

```bash
# ❌ Don't use long command lines
eksctl create cluster --name my-cluster --region ap-southeast-1 --nodegroup-name my-nodes --node-type t3.medium --nodes 2 --spot

# ✅ Do use config files
eksctl create cluster -f cluster-config.yaml
```

### 2. Version Control

```bash
# Store configs in git
git add cluster-config.yaml
git commit -m "Add cluster configuration"
git push
```

### 3. Use Spot for Dev/Test

```yaml
# Cost savings
managedNodeGroups:
  - name: dev-nodes
    spot: true  # 70% cheaper!
```

### 4. Tag Resources

```yaml
# Easy cost tracking
managedNodeGroups:
  - name: my-nodes
    tags:
      Environment: production
      Project: my-app
      Owner: team-a
```

### 5. Enable Logging

```yaml
# Troubleshooting and auditing
cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit"]
    logRetentionInDays: 7  # Short retention = lower cost
```

---

## 🚀 Common Workflows

### Quick Dev Cluster

```bash
# Create
eksctl create cluster \
  --name dev-cluster \
  --region ap-southeast-1 \
  --node-type t3.small \
  --nodes 2 \
  --spot

# Use
kubectl get nodes

# Delete when done
eksctl delete cluster --name dev-cluster
```

### Production Cluster

```bash
# Create from config
eksctl create cluster -f production-config.yaml

# Monitor creation
kubectl get nodes -w

# Verify
kubectl cluster-info
kubectl get pods -n kube-system
```

### Update Workflow

```bash
# Update config file
vim cluster-config.yaml

# Apply changes
eksctl update cluster -f cluster-config.yaml --approve

# Verify
eksctl get cluster --name my-cluster
```

---

## 📊 Cluster Information

```bash
# Get all info
eksctl get cluster --name my-cluster -o yaml

# Get specific details
eksctl get cluster --name my-cluster -o json | jq '.Name'

# List resources
eksctl get nodegroup --cluster my-cluster
eksctl get iamserviceaccount --cluster my-cluster
eksctl get addon --cluster my-cluster
```

---

## 🛠️ Useful Combinations

```bash
# Create and wait
eksctl create cluster -f config.yaml && kubectl get nodes

# List all clusters in all regions
for region in us-east-1 us-west-2 ap-southeast-1; do
  echo "Region: $region"
  eksctl get cluster --region $region
done

# Delete all clusters (BE CAREFUL!)
eksctl get cluster -o json | jq -r '.[].Name' | xargs -I {} eksctl delete cluster --name {}

# Backup cluster config
eksctl get cluster --name my-cluster -o yaml > cluster-backup.yaml
```

---

## 💰 Cost Management

```bash
# Use Spot instances
spot: true

# Smaller instances
instanceType: t3.small  # Instead of t3.large

# Fewer nodes
minSize: 2
maxSize: 2

# Short log retention
logRetentionInDays: 1

# Delete when not in use
eksctl delete cluster --name my-cluster
```

---

## 📚 Resources

- [eksctl Documentation](https://eksctl.io/)
- [eksctl GitHub](https://github.com/weaveworks/eksctl)
- [eksctl Schema](https://eksctl.io/usage/schema/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

