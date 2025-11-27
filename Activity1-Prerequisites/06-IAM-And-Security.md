# IAM and Security Best Practices

**Estimated Reading Time: 30 minutes**

---

## 🔐 What is IAM?

**IAM (Identity and Access Management)** controls who can access what in AWS.

**Simple analogy:** IAM is like a bouncer at a club - decides who gets in and what they can do inside.

---

## 🆚 Traditional vs AWS IAM

### Traditional Security Model

```
Linux Server:
├── Users (john, mary, admin)
│   └── Login with password/SSH key
├── Groups (sudo, www-data)
│   └── User belongs to groups
├── Permissions (read, write, execute)
│   └── File/directory permissions
└── sudo
    └── Elevated privileges

Service accounts:
└── Special users for services (mysql, nginx)
```

### AWS IAM Model

```
AWS Account:
├── IAM Users (people)
│   └── Login with password/MFA
├── IAM Groups (collections)
│   └── Users belong to groups
├── IAM Policies (permissions)
│   └── JSON documents
└── IAM Roles (service accounts)
    └── Temporary credentials

Same concepts, different implementation!
```

---

## 👤 IAM Users

### What are IAM Users?

**Actual people who use AWS.**

```
IAM User: john@company.com
├── Permanent credentials
├── Password (Console access)
├── Access Keys (CLI/API access)
└── Policies attached
    └── Defines what they can do
```

**Traditional equivalent:**

```
Traditional:           AWS IAM:
Linux user        →    IAM User
/etc/passwd       →    IAM database
SSH key           →    Access Key
sudo access       →    Administrator policy
```

### Creating IAM User (Conceptual)

```
User: DevTeamMember
├── Username: dev-john
├── Password: Enable (for Console)
├── Access Keys: Create (for CLI)
└── Permissions:
    ├── Can view EC2 instances
    ├── Can create/delete EKS clusters
    └── Cannot access billing
```

---

## 👥 IAM Groups

### What are IAM Groups?

**Collections of users with same permissions.**

```
Group: Developers
├── Members:
│   ├── john@company.com
│   ├── mary@company.com
│   └── bob@company.com
└── Policies:
    ├── AmazonEKSClusterPolicy
    ├── AmazonEC2ReadOnlyAccess
    └── Can deploy to dev/staging only

Group: Administrators
├── Members:
│   └── admin@company.com
└── Policies:
    └── AdministratorAccess (full access)
```

**Traditional equivalent:**

```
Traditional:           AWS IAM:
Linux groups      →    IAM Groups
/etc/group        →    IAM Groups
sudo group        →    Admin group
docker group      →    Developers group
```

**Best practice:**

```
❌ Don't: Attach policies to individual users
✅ Do: Create groups, attach policies to groups
    └── Add users to groups
    └── Easier to manage!
```

---

## 🎭 IAM Roles

### What are IAM Roles?

**Temporary credentials for AWS services or applications.**

```
Role = Service account

Key difference from Users:
├── Users: Permanent credentials
└── Roles: Temporary credentials
    ├── Auto-rotate
    ├── No password/access keys
    └── Assumed when needed
```

**Traditional equivalent:**

```
Traditional:              AWS IAM Role:
Service account      →    IAM Role
mysql user           →    RDS role
nginx user           →    EC2 role
API key rotation     →    Automatic with roles
```

### When to Use Roles

```
✅ EC2 instance needs S3 access
   └── Attach IAM role to EC2
   └── EC2 assumes role automatically

✅ Lambda function needs DynamoDB access
   └── Lambda execution role

✅ EKS cluster needs to manage resources
   └── EKS cluster role

❌ Don't hard-code AWS keys in code!
   └── Use roles instead
```

### EKS Roles Explained

```
1. EKS Cluster Service Role
   ├── Used by: EKS Control Plane
   ├── Purpose: Manage AWS resources on your behalf
   └── Policies:
       └── AmazonEKSClusterPolicy
           ├── Create/delete load balancers
           ├── Manage security groups
           ├── Describe VPC resources
           └── Manage ENIs

2. EKS Node Instance Role
   ├── Used by: Worker Nodes (EC2 instances)
   ├── Purpose: Allow nodes to function
   └── Policies:
       ├── AmazonEKSWorkerNodePolicy
       │   └── Register with EKS cluster
       ├── AmazonEKS_CNI_Policy
       │   └── Manage network interfaces
       ├── AmazonEC2ContainerRegistryReadOnly
       │   └── Pull container images
       ├── AmazonEBSCSIDriverPolicy
       │   └── Attach EBS volumes
       └── CloudWatchAgentServerPolicy
           └── Send logs to CloudWatch
```

**Role assumption flow:**

```
1. EC2 instance starts
   │
   ▼
2. Instance profile attached
   ├── Contains IAM role
   │
   ▼
3. Instance queries metadata service
   ├── http://169.254.169.254/latest/meta-data/iam/...
   │
   ▼
4. Receives temporary credentials
   ├── Access Key
   ├── Secret Key
   ├── Session Token
   └── Expiry time (usually 6 hours)
   │
   ▼
5. Uses credentials for AWS API calls
   │
   ▼
6. Credentials auto-rotate before expiry
```

---

## 📜 IAM Policies

### What are IAM Policies?

**JSON documents that define permissions.**

```
Policy = List of permissions

Structure:
├── Version: "2012-10-17" (policy language version)
└── Statement: (array of permissions)
    ├── Effect: Allow or Deny
    ├── Action: What operations
    ├── Resource: On what resources
    └── Condition: Under what conditions (optional)
```

### Simple Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes"
      ],
      "Resource": "*"
    }
  ]
}
```

**Reads as:** "Allow describing EC2 instances and volumes on all resources"

### Policy Components

```
Effect:
├── Allow: Grant permission
└── Deny: Explicitly deny (overrides Allow)

Action:
├── service:operation
├── Examples:
│   ├── ec2:RunInstances
│   ├── s3:GetObject
│   ├── eks:DescribeCluster
│   └── iam:CreateRole
└── Wildcards:
    ├── ec2:* (all EC2 actions)
    └── *:* (all actions)

Resource:
├── ARN (Amazon Resource Name)
├── Examples:
│   ├── arn:aws:ec2:us-east-1:123456789012:instance/*
│   ├── arn:aws:s3:::my-bucket/*
│   └── * (all resources)
└── Wildcards supported

Condition (optional):
├── Add constraints
└── Examples:
    ├── IP address restrictions
    ├── MFA required
    └── Time-based access
```

### Real EKS Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:CreateCluster",
        "eks:DeleteCluster"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::*:role/eks-*"
    }
  ]
}
```

**Reads as:**
1. Allow EKS cluster operations
2. Allow reading VPC information
3. Allow passing IAM roles (for EKS to use)

### Policy Types

```
1. AWS Managed Policies
   ├── Created and maintained by AWS
   ├── Ready to use
   └── Examples:
       ├── AmazonEKSClusterPolicy
       ├── AmazonEKSWorkerNodePolicy
       └── AdministratorAccess

2. Customer Managed Policies
   ├── You create
   ├── Reusable across users/groups/roles
   └── Use case: Company-specific permissions

3. Inline Policies
   ├── Embedded directly in user/group/role
   ├── 1:1 relationship
   └── Use case: One-off permissions
```

---

## 🔒 Security Best Practices

### 1. Principle of Least Privilege

**Give only the permissions needed, nothing more.**

```
❌ Bad:
Policy:
└── Action: "*"  (all actions)
    Resource: "*"  (all resources)

✅ Good:
Policy:
└── Action: ["ec2:DescribeInstances"]
    Resource: "*"

Better:
└── Action: ["ec2:DescribeInstances"]
    Resource: "arn:aws:ec2:ap-southeast-1:123456789012:instance/*"
```

**Traditional equivalent:**

```bash
# Bad: Give root access
usermod -aG sudo john

# Good: Give specific permission
john ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
```

### 2. Use IAM Roles, Not Access Keys

```
❌ Bad: Hard-code credentials
// In your code:
const AWS = require('aws-sdk');
AWS.config.update({
  accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
  secretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
});

✅ Good: Use IAM role
// No credentials in code
const AWS = require('aws-sdk');
// Credentials from instance role automatically
```

**Why roles are better:**

```
Access Keys:
├── Stored in code (security risk)
├── Can be leaked
├── Shared across environments
├── Manual rotation needed
└── Hard to track usage

IAM Roles:
├── No credentials in code
├── Can't be leaked
├── Per-resource assignment
├── Auto-rotation
└── AWS tracks usage
```

### 3. Enable MFA (Multi-Factor Authentication)

```
MFA = Something you know + Something you have

Without MFA:
└── Password only
    └── If stolen = account compromised

With MFA:
├── Password (something you know)
└── + MFA code (something you have)
    └── Even if password stolen, need MFA device
```

### 4. Rotate Credentials Regularly

```
Access Keys:
├── Rotate every 90 days
├── Delete unused keys
└── Use AWS Secrets Manager for automation

Passwords:
├── Enforce password policy
├── Minimum length
├── Require complexity
└── Expiration period
```

### 5. Use AWS CloudTrail

**Log all AWS API calls.**

```
CloudTrail logs:
├── Who: Which user/role
├── What: Which action
├── When: Timestamp
├── Where: IP address
└── Result: Success/failure

Example log:
{
  "userIdentity": {
    "userName": "john"
  },
  "eventName": "DeleteCluster",
  "eventTime": "2024-01-15T10:30:00Z",
  "sourceIPAddress": "203.0.113.50",
  "responseElements": {
    "cluster": {
      "name": "production-cluster"
    }
  }
}

→ John deleted production-cluster at 10:30 AM
```

**Use cases:**

```
✅ Security audit
✅ Compliance
✅ Troubleshooting
✅ Incident response
✅ "Who deleted that?!"
```

### 6. Separate Environments

```
Different AWS accounts:
├── Development account
├── Staging account
└── Production account

Benefits:
├── Blast radius containment
├── Cost tracking per environment
├── Different permission levels
└── Production isolation
```

**Or use namespaces in Kubernetes:**

```
Same cluster, different namespaces:
├── Namespace: development
├── Namespace: staging
└── Namespace: production

With RBAC (Role-Based Access Control):
├── Developers: Full access to dev/staging
└── Operators: Full access to production
```

---

## 🎯 IAM for EKS: Complete Picture

### Roles Needed

```
1. Your IAM User/Role
   └── To create/manage EKS cluster
   └── Needs: EKS, EC2, VPC permissions

2. EKS Cluster Service Role
   └── For EKS control plane
   └── Policy: AmazonEKSClusterPolicy

3. EKS Node Instance Role
   └── For worker nodes
   └── Policies:
       ├── AmazonEKSWorkerNodePolicy
       ├── AmazonEKS_CNI_Policy
       ├── AmazonEC2ContainerRegistryReadOnly
       └── Others as needed

4. Pod Service Accounts (IRSA)
   └── For pods needing AWS access
   └── Example: Pod needs S3 access
```

### Trust Relationships

**Defines who can assume a role.**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Reads as:** "Allow EKS service to assume this role"

**For EC2 instances:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Reads as:** "Allow EC2 instances to assume this role"

---

## 📊 IAM Hierarchy Summary

```
AWS Account: 123456789012
│
├── IAM Users (people)
│   ├── john@company.com
│   └── mary@company.com
│
├── IAM Groups
│   ├── Developers
│   │   └── Contains: john, mary
│   └── Administrators
│       └── Contains: admin
│
├── IAM Roles (service accounts)
│   ├── EKSClusterRole
│   │   ├── Trust: eks.amazonaws.com
│   │   └── Policy: AmazonEKSClusterPolicy
│   │
│   └── EKSNodeRole
│       ├── Trust: ec2.amazonaws.com
│       └── Policies:
│           ├── AmazonEKSWorkerNodePolicy
│           ├── AmazonEKS_CNI_Policy
│           └── AmazonEC2ContainerRegistryReadOnly
│
└── IAM Policies
    ├── AWS Managed
    │   ├── AmazonEKSClusterPolicy
    │   └── AmazonEKSWorkerNodePolicy
    └── Customer Managed
        └── CompanySpecificPolicy
```

---

## ✅ Key Takeaways

### IAM Core Concepts:
- **Users**: Permanent credentials (people)
- **Groups**: Collections of users
- **Roles**: Temporary credentials (services)
- **Policies**: JSON permission documents

### EKS Roles:
- **Cluster Role**: For EKS control plane
- **Node Role**: For worker nodes
- **Pod Service Accounts**: For pods (IRSA)

### Best Practices:
- ✅ Least privilege principle
- ✅ Use roles, not access keys
- ✅ Enable MFA
- ✅ Rotate credentials
- ✅ Use CloudTrail for auditing
- ✅ Separate environments

### Security Layers:
```
1. AWS IAM (who can access AWS)
2. Security Groups (network security)
3. Kubernetes RBAC (who can do what in K8s)
4. Network Policies (pod-to-pod security)
5. Application (auth in your app)
```

---

## 🎓 You've Completed Activity 1!

Congratulations! You now understand:

- ✅ Why Kubernetes exists
- ✅ Traditional vs cloud-native comparison
- ✅ Docker and containers
- ✅ Kubernetes core concepts
- ✅ AWS fundamentals (EC2, VPC)
- ✅ Cloud networking
- ✅ IAM and security

**You're ready for hands-on activities!**

---

## 🚀 Next Steps

**Move to Activity 2:** [../Activity2-Tools-And-Commands/README.md](../Activity2-Tools-And-Commands/README.md)

Install the tools needed:
- AWS CLI
- kubectl
- eksctl

Then we'll get hands-on with EKS! 🎯

---

**Remember:** IAM is about controlling access. Think of it as your security guard system! 🔐

