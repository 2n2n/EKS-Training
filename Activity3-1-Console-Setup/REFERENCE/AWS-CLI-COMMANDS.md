# AWS CLI Command Reference

Complete reference for AWS CLI commands used in this workshop.

---

## 📋 Table of Contents

- [General Commands](#general-commands)
- [EKS Commands](#eks-commands)
- [EC2 Commands](#ec2-commands)
- [ECR Commands](#ecr-commands)
- [IAM Commands](#iam-commands)

---

## General Commands

### Configuration

```bash
# Initial setup
aws configure
# Prompts for: Access Key, Secret Key, Region, Output Format

# View current configuration
aws configure list

# Get current identity
aws sts get-caller-identity

# Get account ID only
aws sts get-caller-identity --query 'Account' --output text

# Set default region
aws configure set region ap-southeast-1

# Use specific profile
aws --profile <profile-name> <command>
```

---

## EKS Commands

### Cluster Operations

```bash
# LIST clusters
aws eks list-clusters --region ap-southeast-1

# DESCRIBE cluster
aws eks describe-cluster \
    --name <cluster-name> \
    --region ap-southeast-1

# Get cluster status
aws eks describe-cluster \
    --name <cluster-name> \
    --region ap-southeast-1 \
    --query 'cluster.status'

# Get cluster endpoint
aws eks describe-cluster \
    --name <cluster-name> \
    --region ap-southeast-1 \
    --query 'cluster.endpoint' \
    --output text

# Get cluster version
aws eks describe-cluster \
    --name <cluster-name> \
    --region ap-southeast-1 \
    --query 'cluster.version'

# CREATE cluster
aws eks create-cluster \
    --name <cluster-name> \
    --role-arn <cluster-role-arn> \
    --resources-vpc-config subnetIds=<subnet1>,<subnet2>,securityGroupIds=<sg-id> \
    --kubernetes-version 1.28 \
    --region ap-southeast-1

# DELETE cluster
aws eks delete-cluster \
    --name <cluster-name> \
    --region ap-southeast-1

# UPDATE kubeconfig (connect kubectl to cluster)
aws eks update-kubeconfig \
    --name <cluster-name> \
    --region ap-southeast-1

# Update with alias
aws eks update-kubeconfig \
    --name <cluster-name> \
    --region ap-southeast-1 \
    --alias <my-alias>
```

### Node Group Operations

```bash
# LIST node groups
aws eks list-nodegroups \
    --cluster-name <cluster-name> \
    --region ap-southeast-1

# DESCRIBE node group
aws eks describe-nodegroup \
    --cluster-name <cluster-name> \
    --nodegroup-name <nodegroup-name> \
    --region ap-southeast-1

# Get node group status
aws eks describe-nodegroup \
    --cluster-name <cluster-name> \
    --nodegroup-name <nodegroup-name> \
    --region ap-southeast-1 \
    --query 'nodegroup.status'

# CREATE node group
aws eks create-nodegroup \
    --cluster-name <cluster-name> \
    --nodegroup-name <nodegroup-name> \
    --node-role <node-role-arn> \
    --subnets <subnet1> <subnet2> \
    --instance-types t3.medium \
    --capacity-type SPOT \
    --scaling-config minSize=1,maxSize=3,desiredSize=2 \
    --disk-size 20 \
    --region ap-southeast-1

# UPDATE node group (scaling)
aws eks update-nodegroup-config \
    --cluster-name <cluster-name> \
    --nodegroup-name <nodegroup-name> \
    --scaling-config minSize=1,maxSize=5,desiredSize=3 \
    --region ap-southeast-1

# DELETE node group
aws eks delete-nodegroup \
    --cluster-name <cluster-name> \
    --nodegroup-name <nodegroup-name> \
    --region ap-southeast-1

# WAIT for node group deletion
aws eks wait nodegroup-deleted \
    --cluster-name <cluster-name> \
    --nodegroup-name <nodegroup-name> \
    --region ap-southeast-1
```

### Add-ons

```bash
# LIST add-ons
aws eks list-addons \
    --cluster-name <cluster-name> \
    --region ap-southeast-1

# DESCRIBE add-on
aws eks describe-addon \
    --cluster-name <cluster-name> \
    --addon-name <addon-name> \
    --region ap-southeast-1

# CREATE add-on
aws eks create-addon \
    --cluster-name <cluster-name> \
    --addon-name vpc-cni \
    --region ap-southeast-1
```

---

## EC2 Commands

### VPC Operations

```bash
# LIST VPCs
aws ec2 describe-vpcs --region ap-southeast-1

# Describe specific VPC
aws ec2 describe-vpcs \
    --vpc-ids <vpc-id> \
    --region ap-southeast-1

# Find VPC by name
aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=<vpc-name>" \
    --region ap-southeast-1

# CREATE VPC
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=my-vpc}]' \
    --region ap-southeast-1

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
    --vpc-id <vpc-id> \
    --enable-dns-hostnames '{"Value":true}'

# DELETE VPC
aws ec2 delete-vpc --vpc-id <vpc-id> --region ap-southeast-1
```

### Subnet Operations

```bash
# LIST subnets
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

# CREATE subnet
aws ec2 create-subnet \
    --vpc-id <vpc-id> \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ap-southeast-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-subnet}]' \
    --region ap-southeast-1

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute \
    --subnet-id <subnet-id> \
    --map-public-ip-on-launch

# DELETE subnet
aws ec2 delete-subnet --subnet-id <subnet-id> --region ap-southeast-1
```

### Internet Gateway

```bash
# LIST internet gateways
aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

# CREATE internet gateway
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-igw}]' \
    --region ap-southeast-1

# ATTACH to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id <igw-id> \
    --vpc-id <vpc-id>

# DETACH from VPC
aws ec2 detach-internet-gateway \
    --internet-gateway-id <igw-id> \
    --vpc-id <vpc-id>

# DELETE internet gateway
aws ec2 delete-internet-gateway --internet-gateway-id <igw-id>
```

### Route Tables

```bash
# LIST route tables
aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

# CREATE route table
aws ec2 create-route-table \
    --vpc-id <vpc-id> \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=my-rt}]'

# CREATE route
aws ec2 create-route \
    --route-table-id <rt-id> \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id <igw-id>

# ASSOCIATE with subnet
aws ec2 associate-route-table \
    --route-table-id <rt-id> \
    --subnet-id <subnet-id>

# DELETE route table
aws ec2 delete-route-table --route-table-id <rt-id>
```

### Security Groups

```bash
# LIST security groups
aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --region ap-southeast-1

# CREATE security group
aws ec2 create-security-group \
    --group-name my-sg \
    --description "My security group" \
    --vpc-id <vpc-id> \
    --region ap-southeast-1

# ADD inbound rule
aws ec2 authorize-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# ADD inbound rule (port range)
aws ec2 authorize-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 30000-32767 \
    --cidr 0.0.0.0/0

# REMOVE inbound rule
aws ec2 revoke-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

# DELETE security group
aws ec2 delete-security-group --group-id <sg-id>
```

### EC2 Instances

```bash
# LIST instances
aws ec2 describe-instances \
    --region ap-southeast-1

# Filter by tag
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*eks*" \
    --region ap-southeast-1

# Get instance IDs
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].InstanceId' \
    --output text
```

---

## ECR Commands

### Repository Operations

```bash
# LIST repositories
aws ecr describe-repositories --region ap-southeast-1

# DESCRIBE repository
aws ecr describe-repositories \
    --repository-names <repo-name> \
    --region ap-southeast-1

# Get repository URI
aws ecr describe-repositories \
    --repository-names <repo-name> \
    --region ap-southeast-1 \
    --query 'repositories[0].repositoryUri' \
    --output text

# CREATE repository
aws ecr create-repository \
    --repository-name <repo-name> \
    --image-scanning-configuration scanOnPush=true \
    --region ap-southeast-1

# DELETE repository (must be empty or use --force)
aws ecr delete-repository \
    --repository-name <repo-name> \
    --force \
    --region ap-southeast-1
```

### Image Operations

```bash
# LIST images
aws ecr list-images \
    --repository-name <repo-name> \
    --region ap-southeast-1

# DESCRIBE images
aws ecr describe-images \
    --repository-name <repo-name> \
    --region ap-southeast-1

# Describe specific image
aws ecr describe-images \
    --repository-name <repo-name> \
    --image-ids imageTag=<tag> \
    --region ap-southeast-1

# DELETE image
aws ecr batch-delete-image \
    --repository-name <repo-name> \
    --image-ids imageTag=<tag> \
    --region ap-southeast-1

# Delete multiple images
aws ecr batch-delete-image \
    --repository-name <repo-name> \
    --image-ids imageTag=v1 imageTag=v2 \
    --region ap-southeast-1
```

### Authentication

```bash
# Get login password
aws ecr get-login-password --region ap-southeast-1

# Full login command
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
```

### Lifecycle Policies

```bash
# GET lifecycle policy
aws ecr get-lifecycle-policy \
    --repository-name <repo-name> \
    --region ap-southeast-1

# PUT lifecycle policy
aws ecr put-lifecycle-policy \
    --repository-name <repo-name> \
    --lifecycle-policy-text file://lifecycle-policy.json \
    --region ap-southeast-1
```

---

## IAM Commands

### Role Operations

```bash
# LIST roles
aws iam list-roles

# Filter by path
aws iam list-roles --path-prefix /eks/

# GET role
aws iam get-role --role-name <role-name>

# CREATE role
aws iam create-role \
    --role-name <role-name> \
    --assume-role-policy-document file://trust-policy.json

# DELETE role
aws iam delete-role --role-name <role-name>

# ATTACH policy to role
aws iam attach-role-policy \
    --role-name <role-name> \
    --policy-arn <policy-arn>

# DETACH policy from role
aws iam detach-role-policy \
    --role-name <role-name> \
    --policy-arn <policy-arn>

# LIST attached policies
aws iam list-attached-role-policies --role-name <role-name>
```

### Common Policy ARNs

```bash
# EKS Cluster Policy
arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# EKS Worker Node Policy
arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

# ECR Read Only
arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# EKS CNI Policy
arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
```

### User Operations

```bash
# LIST users
aws iam list-users

# GET user
aws iam get-user --user-name <username>

# CREATE user
aws iam create-user --user-name <username>

# CREATE access key
aws iam create-access-key --user-name <username>

# LIST access keys
aws iam list-access-keys --user-name <username>

# DELETE access key
aws iam delete-access-key \
    --user-name <username> \
    --access-key-id <key-id>
```

---

## 📝 Output Formatting

```bash
# JSON output (default)
aws eks list-clusters --output json

# Table output
aws eks list-clusters --output table

# Text output
aws eks list-clusters --output text

# Query specific field
aws eks describe-cluster --name <name> --query 'cluster.status'

# Query with output format
aws eks describe-cluster --name <name> --query 'cluster.endpoint' --output text
```

---

## 🔗 Additional Resources

- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/)
- [EKS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/eks/)
- [EC2 CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ec2/)
- [ECR CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/ecr/)
- [IAM CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/iam/)

