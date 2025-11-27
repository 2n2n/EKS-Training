# AWS Fundamentals for EKS

**Estimated Reading Time: 30 minutes**

---

## ☁️ What is AWS?

**Amazon Web Services (AWS)** is a cloud computing platform that provides on-demand computing resources.

**Simple analogy:** AWS is like renting servers, networks, and storage instead of buying and maintaining your own.

---

## 🗺️ Traditional Hosting vs AWS

### Traditional Hosting

```
Your Setup:
├── Buy/rent physical server
├── Install in data center
├── Pay for power, cooling, security
├── Pay 24/7 (even if not using)
├── Hardware fails? You fix it
└── Need more? Buy more servers

Costs: High upfront + fixed monthly
Flexibility: Low (takes days/weeks to scale)
```

### AWS Cloud

```
AWS Setup:
├── Rent virtual servers (EC2)
├── AWS manages physical infrastructure
├── Pay only for what you use
├── Scale up/down instantly
├── Hardware fails? AWS replaces it
└── Need more? Click a button

Costs: Pay as you go (hourly/per-second)
Flexibility: High (scale in minutes)
```

---

## 🌍 AWS Global Infrastructure

### Regions

**What:** Physical locations around the world where AWS has data centers.

```
AWS Regions (examples):
├── us-east-1 (N. Virginia, USA)
├── us-west-2 (Oregon, USA)
├── eu-west-1 (Ireland, Europe)
├── ap-southeast-1 (Singapore, Asia) ← We'll use this
├── ap-northeast-1 (Tokyo, Japan)
└── ... 30+ regions worldwide
```

**Traditional equivalent:**

```
Traditional:            AWS:
Your data center   →    AWS Region
Server rack        →    Availability Zone
Physical server    →    EC2 Instance
```

**Why it matters:**

- **Latency**: Choose region closest to users
- **Compliance**: Data residency requirements
- **Cost**: Prices vary by region
- **Services**: Not all services in all regions

**For this training:** We use `ap-southeast-1` (Singapore)

### Availability Zones (AZs)

**What:** Separate data centers within a region.

```
Region: ap-southeast-1 (Singapore)
├── ap-southeast-1a (Data Center 1)
├── ap-southeast-1b (Data Center 2)
└── ap-southeast-1c (Data Center 3)

Each AZ:
- Isolated from others
- Independent power
- Separate network
- Protected from failures
```

**Traditional equivalent:**

```
Traditional:               AWS:
Backup data center    →    Different AZ
Server redundancy     →    Multi-AZ deployment
```

**Why it matters:**

- **High Availability**: If one AZ fails, others continue
- **Disaster Recovery**: Spread resources across AZs
- **Best Practice**: Always use multiple AZs

**Example:**

```
Bad (Single AZ):
Node 1: ap-southeast-1a
Node 2: ap-southeast-1a
→ AZ fails = all nodes down 😱

Good (Multi-AZ):
Node 1: ap-southeast-1a
Node 2: ap-southeast-1b
→ AZ fails = other nodes still running ✅
```

---

## 🖥️ EC2 - Elastic Compute Cloud

### What is EC2?

**Virtual servers in the cloud.**

```
EC2 Instance = Virtual server

Traditional:               AWS EC2:
Physical server       →    Virtual machine
RAM, CPU, Disk        →    Instance type
Operating System      →    AMI (Amazon Machine Image)
Server room           →    AWS data center
```

### Instance Types

**Different sizes for different needs:**

```
Instance Type: t3.medium (what we'll use)
├── vCPU: 2 cores
├── RAM: 4 GB
├── Network: Moderate
└── Cost: ~$0.0416/hour ($30/month)

Common types:
├── t3.micro: 2 vCPU, 1 GB RAM (~$7/month)
├── t3.small: 2 vCPU, 2 GB RAM (~$15/month)
├── t3.medium: 2 vCPU, 4 GB RAM (~$30/month)
├── t3.large: 2 vCPU, 8 GB RAM (~$60/month)
└── ... many more sizes
```

**Traditional equivalent:**

```
VPS Plans:              AWS EC2:
Shared hosting    →     t3.micro
Basic VPS         →     t3.small/medium
Dedicated server  →     Larger instances
```

### Spot Instances (70% Cheaper!)

```
On-Demand Instance:
- Always available
- Pay full price
- $0.0416/hour

Spot Instance:
- Use spare AWS capacity
- Up to 70% discount!
- $0.0125/hour
- Can be terminated if AWS needs capacity
```

**When to use Spot:**

- ✅ Development/Testing
- ✅ Batch jobs
- ✅ Stateless applications
- ✅ **Kubernetes workers** (EKS handles termination)
- ❌ Databases
- ❌ Critical production (without backup)

**For this training:** We use Spot instances to save money!

### EC2 Storage

```
EC2 Instance
└── EBS Volume (Elastic Block Store)
    └── Like a virtual hard drive
        ├── Attached to EC2 instance
        ├── Persists if instance stops
        └── Can be backed up (snapshots)

Volume types:
├── gp3: General purpose SSD (what we use)
│   └── $0.08/GB/month, fast, balanced
├── gp2: Older general purpose
│   └── $0.10/GB/month
└── io2: High performance
    └── $0.125/GB/month + IOPS cost
```

**Traditional equivalent:**

```
Traditional:          AWS EBS:
Hard drive       →    EBS Volume
RAID array       →    Multiple volumes
Disk backup      →    EBS Snapshot
```

**For this training:** 20 GB gp3 volumes ($1.60/month each)

---

## 🌐 VPC - Virtual Private Cloud

### What is VPC?

**Your private network in AWS.**

```
VPC = Your isolated network in the cloud

Traditional:              AWS VPC:
Your network         →    VPC
IP address range     →    CIDR block (e.g., 10.0.0.0/16)
Network segments     →    Subnets
Router               →    Route tables
Firewall             →    Security Groups
```

### VPC CIDR Block

```
VPC CIDR: 10.0.0.0/16
├── Gives you: 65,536 IP addresses
├── Range: 10.0.0.0 to 10.0.255.255
└── Private network (not routable on internet)

Common private IP ranges:
├── 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
├── 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
└── 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)
```

### Subnets

**Subdivisions of your VPC.**

```
VPC: 10.0.0.0/16
├── Subnet A: 10.0.1.0/24 (256 IPs)
│   └── Availability Zone: ap-southeast-1a
└── Subnet B: 10.0.2.0/24 (256 IPs)
    └── Availability Zone: ap-southeast-1b

Public Subnet:
- Has route to Internet Gateway
- Can access internet
- Gets public IP

Private Subnet:
- No direct internet access
- More secure
- Uses NAT Gateway for outbound
```

**For this training:** We use public subnets only (saves NAT Gateway cost)

### Internet Gateway

**Allows VPC to access the internet.**

```
Internet
   │
   ▼
┌──────────────────┐
│ Internet Gateway │
└──────────────────┘
   │
   ▼
┌──────────────────┐
│      VPC         │
│                  │
│  Public Subnet   │
│  ├── EC2 1       │
│  └── EC2 2       │
└──────────────────┘
```

**Traditional equivalent:**

```
Traditional:         AWS:
Router with WAN  →   Internet Gateway
Public IPs       →   Elastic IPs
```

### Route Tables

**Define where network traffic goes.**

```
Route Table (Public Subnet):
├── 10.0.0.0/16 → local (internal VPC traffic)
└── 0.0.0.0/0 → Internet Gateway (all other traffic)

This means:
- Traffic to 10.0.x.x stays in VPC
- Everything else goes to internet
```

**Traditional equivalent:**

```
Traditional:           AWS:
ip route commands  →   Route Tables
Default gateway    →   0.0.0.0/0 route
```

---

## 🔐 Security Groups

### What are Security Groups?

**Virtual firewalls for EC2 instances.**

```
Security Group = Firewall rules

Traditional:              AWS:
iptables rules       →    Security Group
ufw/firewalld        →    Security Group
Port forwarding      →    Security Group rules
```

### How They Work

```
EC2 Instance
└── Security Group: "web-server-sg"
    ├── Inbound Rules (incoming traffic)
    │   ├── Allow: Port 80 from 0.0.0.0/0
    │   ├── Allow: Port 443 from 0.0.0.0/0
    │   └── Allow: Port 22 from your-ip
    └── Outbound Rules (outgoing traffic)
        └── Allow: All traffic to anywhere (default)
```

**Example Security Group:**

```
Name: eks-node-sg

Inbound:
├── Port 443 (HTTPS)
│   └── From: EKS Control Plane SG
├── Ports 1025-65535
│   └── From: EKS Control Plane SG
├── All traffic
│   └── From: Same security group (pod-to-pod)
└── Port 30000-32767 (NodePort)
    └── From: 0.0.0.0/0 (internet)

Outbound:
└── All traffic to anywhere
```

**Traditional equivalent:**

```bash
# iptables equivalent:
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -s your-ip -j ACCEPT
```

---

## 👤 IAM - Identity and Access Management

### What is IAM?

**Manages who can access what in AWS.**

```
IAM = User and permission management

Traditional:              AWS IAM:
Linux users          →    IAM Users
sudo/root            →    IAM Policies
Service account      →    IAM Roles
SSH keys             →    Access Keys
```

### IAM Users

**Actual people who use AWS.**

```
IAM User: john@company.com
├── Password (for AWS Console)
├── Access Keys (for CLI/API)
└── Policies (what they can do)
    ├── Can create EC2 instances
    ├── Can view S3 buckets
    └── Cannot delete databases
```

### IAM Roles

**Temporary credentials for AWS services.**

```
IAM Role = Service account for AWS resources

Example: EC2 instance needs to access S3
├── Without role: Hard-code AWS keys 😱
└── With role: EC2 assumes role ✅
    └── Temporary credentials
    └── Automatic rotation
```

**For EKS:**

```
EKS Cluster Role:
└── Allows EKS to manage AWS resources
    ├── Create load balancers
    ├── Manage security groups
    └── Describe VPC

EKS Node Role:
└── Allows worker nodes to:
    ├── Pull container images (ECR)
    ├── Send logs (CloudWatch)
    └── Attach storage (EBS)
```

### IAM Policies

**Documents that define permissions.**

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

**Reads as:** "Allow describing EC2 instances and volumes"

**Common policy types:**

```
AWS Managed Policies:
├── AmazonEKSClusterPolicy
├── AmazonEKSWorkerNodePolicy
├── AmazonEC2ContainerRegistryReadOnly
└── Created by AWS, ready to use

Customer Managed Policies:
└── You create for specific needs

Inline Policies:
└── Attached directly to user/role
```

---

## 📊 AWS Services Summary for EKS

| Service | Purpose | Traditional Equivalent | Cost |
|---------|---------|----------------------|------|
| **EC2** | Virtual servers | VPS/Dedicated servers | ~$30/month per t3.medium |
| **EBS** | Block storage | Hard drives | ~$1.60/month per 20GB |
| **VPC** | Private network | Your network | Free |
| **EKS** | Managed Kubernetes | Self-hosted K8s | $72/month |
| **IAM** | Access management | User accounts | Free |
| **CloudWatch** | Monitoring/Logs | Log files | ~$1-2/month (minimal) |
| **ECR** | Container registry | Docker Hub | ~$0.10/GB/month |

**Total minimum cost for our setup:** ~$95/month

---

## 🎯 Key Concepts Review

### AWS Hierarchy

```
AWS Account
└── Regions
    └── Availability Zones
        └── VPC
            └── Subnets
                └── EC2 Instances
                    └── EBS Volumes
```

### For EKS Setup

```
What we'll create:
├── VPC (10.0.0.0/16)
│   ├── Public Subnet A (10.0.1.0/24) in AZ-a
│   └── Public Subnet B (10.0.2.0/24) in AZ-b
│
├── Security Groups
│   ├── Control Plane SG
│   └── Node SG
│
├── IAM Roles
│   ├── EKS Cluster Role
│   └── EKS Node Role
│
├── EKS Cluster
│   └── Control Plane (AWS managed)
│
└── Node Group
    ├── EC2 Instance 1 (t3.medium Spot) in AZ-a
    └── EC2 Instance 2 (t3.medium Spot) in AZ-b
```

---

## ✅ Key Takeaways

### AWS Core Services:
- **EC2**: Virtual servers (like VPS)
- **VPC**: Your private network
- **Security Groups**: Firewall rules
- **IAM**: User and permission management
- **EBS**: Virtual hard drives

### Important Concepts:
- **Regions**: Physical locations (choose closest)
- **AZs**: Separate data centers (use multiple)
- **Spot Instances**: Cheap but can be terminated
- **Roles**: Temporary credentials for services
- **CIDR blocks**: IP address ranges

### Cost Optimization:
- ✅ Use Spot instances (70% savings)
- ✅ Right-size instances (don't overprovision)
- ✅ Use gp3 volumes (cheaper than gp2)
- ✅ Delete resources when not needed
- ❌ Don't use NAT Gateway if not required

---

## 🚀 Next Steps

You now understand the AWS services needed for EKS!

**Next:** [05-Networking-Basics.md](05-Networking-Basics.md) - Deep dive into cloud networking!

---

**Remember:** AWS is just infrastructure. Same concepts as physical servers, but virtual and on-demand! ☁️

