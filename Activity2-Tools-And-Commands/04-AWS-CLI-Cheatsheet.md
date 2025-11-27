# AWS CLI Cheatsheet

Quick reference for AWS CLI commands used in EKS training.

---

## 🔐 Identity & Access

```bash
# Who am I?
aws sts get-caller-identity

# List IAM roles
aws iam list-roles

# Get specific role
aws iam get-role --role-name EKSClusterRole

# List policies attached to role
aws iam list-attached-role-policies --role-name EKSClusterRole
```

---

## 🖥️ EC2 (Compute)

```bash
# List all instances
aws ec2 describe-instances

# List running instances only
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Get instance IDs only
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text

# Describe specific instance
aws ec2 describe-instance --instance-id i-1234567890abcdef0

# List all instance types available
aws ec2 describe-instance-types --filters "Name=instance-type,Values=t3.*"

# Stop instance
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Terminate instance
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
```

---

## 🌐 VPC (Networking)

```bash
# List VPCs
aws ec2 describe-vpcs

# List VPCs for EKS cluster
aws ec2 describe-vpcs --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=training-cluster"

# List subnets
aws ec2 describe-subnets

# List subnets in specific VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-12345"

# List internet gateways
aws ec2 describe-internet-gateways

# List route tables
aws ec2 describe-route-tables

# List security groups
aws ec2 describe-security-groups

# Describe specific security group
aws ec2 describe-security-group --group-id sg-12345
```

---

## 🎛️ EKS (Kubernetes)

```bash
# List clusters
aws eks list-clusters

# List clusters in specific region
aws eks list-clusters --region ap-southeast-1

# Describe cluster
aws eks describe-cluster --name training-cluster

# Get cluster status
aws eks describe-cluster --name training-cluster --query 'cluster.status'

# List node groups
aws eks list-nodegroups --cluster-name training-cluster

# Describe node group
aws eks describe-nodegroup --cluster-name training-cluster --nodegroup-name training-nodes

# Update kubeconfig
aws eks update-kubeconfig --name training-cluster --region ap-southeast-1

# List addons
aws eks list-addons --cluster-name training-cluster

# Describe addon
aws eks describe-addon --cluster-name training-cluster --addon-name vpc-cni
```

---

## 📦 ECR (Container Registry)

```bash
# List repositories
aws ecr describe-repositories

# Create repository
aws ecr create-repository --repository-name my-app

# Get login password (for docker login)
aws ecr get-login-password --region ap-southeast-1

# Docker login to ECR
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com

# List images in repository
aws ecr list-images --repository-name my-app

# Delete repository
aws ecr delete-repository --repository-name my-app --force
```

---

## 📊 CloudWatch (Monitoring)

```bash
# List log groups
aws logs describe-log-groups

# List log streams
aws logs describe-log-streams --log-group-name /aws/eks/training-cluster/cluster

# Get logs
aws logs tail /aws/eks/training-cluster/cluster --follow

# Create log group
aws logs create-log-group --log-group-name /my-app/logs

# Delete log group
aws logs delete-log-group --log-group-name /my-app/logs
```

---

## 🏗️ CloudFormation (Infrastructure)

```bash
# List stacks
aws cloudformation list-stacks

# List active stacks only
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Describe stack
aws cloudformation describe-stacks --stack-name eksctl-training-cluster-cluster

# List stack resources
aws cloudformation list-stack-resources --stack-name eksctl-training-cluster-cluster

# Stack events (troubleshooting)
aws cloudformation describe-stack-events --stack-name eksctl-training-cluster-cluster

# Delete stack
aws cloudformation delete-stack --stack-name my-stack
```

---

## 💾 EBS (Storage)

```bash
# List volumes
aws ec2 describe-volumes

# List volumes for cluster
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/training-cluster,Values=owned"

# Create snapshot
aws ec2 create-snapshot --volume-id vol-12345 --description "Backup"

# List snapshots
aws ec2 describe-snapshots --owner-ids self

# Delete volume
aws ec2 delete-volume --volume-id vol-12345
```

---

## 🔍 Query and Filter

### Using --query

```bash
# Get only cluster names
aws eks list-clusters --query 'clusters[]' --output text

# Get instance IDs
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'

# Get instance IDs and states
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output table

# Complex query
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,InstanceType]'
```

### Using --filters

```bash
# Filter by tag
aws ec2 describe-instances --filters "Name=tag:Environment,Values=production"

# Filter by state
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Multiple filters
aws ec2 describe-instances --filters "Name=instance-type,Values=t3.medium" "Name=instance-state-name,Values=running"
```

---

## 📋 Output Formats

```bash
# JSON (default)
aws eks list-clusters --output json

# Table (easier to read)
aws eks list-clusters --output table

# Text (for scripting)
aws eks list-clusters --output text

# YAML
aws eks describe-cluster --name my-cluster --output yaml
```

---

## 🎯 Useful Combinations

```bash
# Count running instances
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' | grep -c "i-"

# Get public IPs of nodes
aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=training-cluster" --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress]' --output table

# List all costs for today
aws ce get-cost-and-usage --time-period Start=$(date +%Y-%m-%d),End=$(date -d tomorrow +%Y-%m-%d) --granularity DAILY --metrics BlendedCost

# Find unused EBS volumes
aws ec2 describe-volumes --filters "Name=status,Values=available" --query 'Volumes[].[VolumeId,Size]' --output table
```

---

## 🛠️ Troubleshooting

```bash
# Check service availability
aws eks list-clusters --region ap-southeast-1

# Describe last error
aws eks describe-cluster --name my-cluster --query 'cluster.resourcesVpcConfig'

# View CloudFormation failures
aws cloudformation describe-stack-events --stack-name eksctl-training-cluster-cluster --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Check quotas
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
```

---

## 💡 Tips

1. **Use profiles for multiple accounts:**
   ```bash
   aws eks list-clusters --profile work
   ```

2. **Set default region:**
   ```bash
   export AWS_DEFAULT_REGION=ap-southeast-1
   ```

3. **Enable CLI auto-completion:**
   ```bash
   complete -C '/usr/local/bin/aws_completer' aws
   ```

4. **Save output to file:**
   ```bash
   aws eks describe-cluster --name my-cluster > cluster-info.json
   ```

5. **Use --dry-run when possible:**
   ```bash
   aws ec2 run-instances --dry-run --image-id ami-12345 --instance-type t3.micro
   ```

---

## 📚 Resources

- [AWS CLI Command Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/index.html)
- [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/)
- [JMESPath Tutorial](https://jmespath.org/tutorial.html) (for --query)

