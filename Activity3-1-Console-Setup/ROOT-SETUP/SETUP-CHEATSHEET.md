# Root Admin Setup Cheatsheet

Quick reference for all commands used to set up the shared EKS environment.

---

## 🔧 Prerequisites Check

```bash
# Verify AWS CLI
aws --version

# Verify kubectl
kubectl version --client

# Verify identity (should show root/admin account)
aws sts get-caller-identity

# Check region
aws configure get region
```

---

## 🌐 VPC & Networking

### Create VPC

```bash
# Create VPC
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=eks-workshop-vpc}]' \
    --region ap-southeast-1

# Enable DNS hostname
aws ec2 modify-vpc-attribute \
    --vpc-id <vpc-id> \
    --enable-dns-hostnames '{"Value":true}'
```

### Create Subnets

```bash
# Public Subnet A
aws ec2 create-subnet \
    --vpc-id <vpc-id> \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ap-southeast-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=eks-public-a},{Key=kubernetes.io/role/elb,Value=1}]'

# Public Subnet B
aws ec2 create-subnet \
    --vpc-id <vpc-id> \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ap-southeast-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=eks-public-b},{Key=kubernetes.io/role/elb,Value=1}]'

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute \
    --subnet-id <subnet-id> \
    --map-public-ip-on-launch
```

### Create Internet Gateway

```bash
# Create IGW
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=eks-workshop-igw}]'

# Attach to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id <igw-id> \
    --vpc-id <vpc-id>
```

### Create Route Table

```bash
# Create route table
aws ec2 create-route-table \
    --vpc-id <vpc-id> \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=eks-public-rt}]'

# Add route to IGW
aws ec2 create-route \
    --route-table-id <rt-id> \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id <igw-id>

# Associate with subnets
aws ec2 associate-route-table --route-table-id <rt-id> --subnet-id <subnet-a-id>
aws ec2 associate-route-table --route-table-id <rt-id> --subnet-id <subnet-b-id>
```

### Create Security Groups

```bash
# Cluster Security Group
aws ec2 create-security-group \
    --group-name eks-cluster-sg \
    --description "EKS Cluster Security Group" \
    --vpc-id <vpc-id>

# Node Security Group
aws ec2 create-security-group \
    --group-name eks-node-sg \
    --description "EKS Node Security Group" \
    --vpc-id <vpc-id>

# Allow NodePort access
aws ec2 authorize-security-group-ingress \
    --group-id <node-sg-id> \
    --protocol tcp \
    --port 30000-32767 \
    --cidr 0.0.0.0/0
```

---

## 👤 IAM Roles

### EKS Cluster Role

```bash
# Create trust policy file
cat > cluster-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "eks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create role
aws iam create-role \
    --role-name eks-workshop-cluster-role \
    --assume-role-policy-document file://cluster-trust-policy.json

# Attach policy
aws iam attach-role-policy \
    --role-name eks-workshop-cluster-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

### EKS Node Role

```bash
# Create trust policy file
cat > node-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create role
aws iam create-role \
    --role-name eks-workshop-node-role \
    --assume-role-policy-document file://node-trust-policy.json

# Attach policies
aws iam attach-role-policy --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam attach-role-policy --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam attach-role-policy --role-name eks-workshop-node-role \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
```

---

## ☸️ EKS Cluster

### Create Cluster

```bash
aws eks create-cluster \
    --name shared-workshop-cluster \
    --role-arn arn:aws:iam::<account-id>:role/eks-workshop-cluster-role \
    --resources-vpc-config \
        subnetIds=<subnet-a-id>,<subnet-b-id>,\
        securityGroupIds=<cluster-sg-id>,\
        endpointPublicAccess=true,\
        endpointPrivateAccess=false \
    --kubernetes-version 1.28 \
    --region ap-southeast-1
```

### Check Status

```bash
# Wait for cluster (takes ~15-20 min)
aws eks describe-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --query 'cluster.status'
```

### Configure kubectl

```bash
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1
```

---

## 🐳 ECR Repository

### Create Repository

```bash
aws ecr create-repository \
    --repository-name eks-workshop-apps \
    --image-scanning-configuration scanOnPush=true \
    --region ap-southeast-1
```

### Set Lifecycle Policy

```bash
aws ecr put-lifecycle-policy \
    --repository-name eks-workshop-apps \
    --lifecycle-policy-text '{
      "rules": [{
        "rulePriority": 1,
        "description": "Keep last 50 images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 50
        },
        "action": {"type": "expire"}
      }]
    }' \
    --region ap-southeast-1
```

### Get Repository URI

```bash
aws ecr describe-repositories \
    --repository-names eks-workshop-apps \
    --region ap-southeast-1 \
    --query 'repositories[0].repositoryUri' \
    --output text
```

---

## 👥 Participant Access

### Update aws-auth ConfigMap

```bash
# Get current config
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth.yaml

# Edit to add users (add under mapUsers section):
# - userarn: arn:aws:iam::<account-id>:user/eks-charles
#   username: charles
#   groups:
#     - system:masters
```

### Apply Updated ConfigMap

```bash
kubectl apply -f aws-auth.yaml
```

### Verify Access

```bash
# As participant
aws sts get-caller-identity
kubectl get nodes
```

---

## 🧹 Cleanup Commands

### Delete in Order

```bash
# 1. Delete node groups
aws eks delete-nodegroup \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \
    --region ap-southeast-1

# Wait for deletion
aws eks wait nodegroup-deleted \
    --cluster-name shared-workshop-cluster \
    --nodegroup-name training-nodes \
    --region ap-southeast-1

# 2. Delete cluster
aws eks delete-cluster \
    --name shared-workshop-cluster \
    --region ap-southeast-1

# 3. Delete ECR images
aws ecr batch-delete-image \
    --repository-name eks-workshop-apps \
    --image-ids "$(aws ecr list-images --repository-name eks-workshop-apps --query 'imageIds[*]' --output json)" \
    --region ap-southeast-1

# 4. Delete ECR repository
aws ecr delete-repository \
    --repository-name eks-workshop-apps \
    --force \
    --region ap-southeast-1

# 5. Delete IAM roles (detach policies first)
aws iam detach-role-policy --role-name eks-workshop-cluster-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name eks-workshop-cluster-role

aws iam detach-role-policy --role-name eks-workshop-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name eks-workshop-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam detach-role-policy --role-name eks-workshop-node-role --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam delete-role --role-name eks-workshop-node-role

# 6. Delete VPC resources
aws ec2 delete-security-group --group-id <node-sg-id>
aws ec2 delete-security-group --group-id <cluster-sg-id>
aws ec2 detach-internet-gateway --internet-gateway-id <igw-id> --vpc-id <vpc-id>
aws ec2 delete-internet-gateway --internet-gateway-id <igw-id>
aws ec2 delete-subnet --subnet-id <subnet-a-id>
aws ec2 delete-subnet --subnet-id <subnet-b-id>
aws ec2 delete-route-table --route-table-id <rt-id>
aws ec2 delete-vpc --vpc-id <vpc-id>
```

---

## 📊 Status Check Commands

```bash
# VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-workshop-vpc" --query 'Vpcs[0].VpcId'

# Subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>" --query 'Subnets[*].[SubnetId,CidrBlock]'

# EKS Cluster
aws eks describe-cluster --name shared-workshop-cluster --query 'cluster.[status,endpoint]'

# Node Groups
aws eks list-nodegroups --cluster-name shared-workshop-cluster
aws eks describe-nodegroup --cluster-name shared-workshop-cluster --nodegroup-name training-nodes --query 'nodegroup.[status,scalingConfig]'

# ECR
aws ecr describe-repositories --repository-names eks-workshop-apps
aws ecr list-images --repository-name eks-workshop-apps

# Nodes
kubectl get nodes
kubectl top nodes

# Participant access test
kubectl auth can-i list pods --as charles
```

---

## 📋 Setup Checklist

- [ ] VPC created with DNS enabled
- [ ] 2 public subnets in different AZs
- [ ] Internet Gateway attached
- [ ] Route table with internet route
- [ ] Security groups created
- [ ] EKS cluster role created
- [ ] EKS node role created
- [ ] EKS cluster created and Active
- [ ] Initial node group created
- [ ] ECR repository created
- [ ] Participants added to aws-auth
- [ ] Participants can access cluster

