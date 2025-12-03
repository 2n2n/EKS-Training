# Activity 3-1 Architecture - Shared EKS Cluster

This document explains the architecture of the shared EKS cluster environment where all 7 participants work together.

---

## 🏗️ Complete Shared Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    AWS Account (ap-southeast-1)                            │
│                           Managed by Root                                  │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                    VPC: 10.0.0.0/16 (Shared)                         │ │
│  │                                                                      │ │
│  │   ┌────────────────────┐              ┌────────────────────┐       │ │
│  │   │  Public Subnet A   │              │  Public Subnet B   │       │ │
│  │   │  10.0.1.0/24       │              │  10.0.2.0/24       │       │ │
│  │   │  AZ: 1a            │              │  AZ: 1b            │       │ │
│  │   │                    │              │                    │       │ │
│  │   │  ┌──────────────┐  │              │  ┌──────────────┐  │       │ │
│  │   │  │   Node 1     │  │              │  │   Node 2     │  │       │ │
│  │   │  │  t3.medium   │  │              │  │  t3.medium   │  │       │ │
│  │   │  │  Spot        │  │              │  │  Spot        │  │       │ │
│  │   │  │  20GB gp3    │  │              │  │  20GB gp3    │  │       │ │
│  │   │  │              │  │              │  │              │  │       │ │
│  │   │  │ All 7 Users' │  │              │  │ All 7 Users' │  │       │ │
│  │   │  │ Pods Run Here│  │              │  │ Pods Run Here│  │       │ │
│  │   │  └──────────────┘  │              │  └──────────────┘  │       │ │
│  │   │                    │              │                    │       │ │
│  │   │  10.0.1.50         │              │  10.0.2.50         │       │ │
│  │   └────────────────────┘              └────────────────────┘       │ │
│  │                                                                      │ │
│  │   ┌──────────────────────────────────────────────────────────────┐ │ │
│  │   │            Internet Gateway                                   │ │ │
│  │   │            (Public Access In/Out)                             │ │ │
│  │   └──────────────────────────────────────────────────────────────┘ │ │
│  │                                                                      │ │
│  │   ┌──────────────────────────────────────────────────────────────┐ │ │
│  │   │            Security Groups                                    │ │ │
│  │   │  Cluster SG: Port 443 (API access)                           │ │ │
│  │   │  Node SG: Inter-node + NodePort 30000-32767                  │ │ │
│  │   └──────────────────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │            EKS Control Plane: shared-workshop-cluster                │ │
│  │            (AWS Managed - Multi-AZ, HA)                              │ │
│  │            Cost: $72/month                                           │ │
│  │                                                                      │ │
│  │   ┌──────────┐    ┌──────────┐    ┌──────────┐   ┌──────────┐    │ │
│  │   │   API    │    │Scheduler │    │Controller│   │   etcd   │    │ │
│  │   │  Server  │───▶│          │───▶│ Manager  │◀─▶│ Database │    │ │
│  │   │  :443    │    │          │    │          │   │          │    │ │
│  │   └──────────┘    └──────────┘    └──────────┘   └──────────┘    │ │
│  │        ▲                                                            │ │
│  │        │ kubectl commands from all 7 participants                  │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │            Kubernetes Namespaces (Logical Isolation)                 │ │
│  │                                                                      │ │
│  │   System Namespaces (Don't Touch!):                                 │ │
│  │   ├── default (system default)                                      │ │
│  │   ├── kube-system (Kubernetes components)                           │ │
│  │   ├── kube-public (public cluster info)                             │ │
│  │   └── kube-node-lease (node health checks)                          │ │
│  │                                                                      │ │
│  │   Participant Namespaces (Your Workspaces):                         │ │
│  │   ├── charles-workspace                                             │ │
│  │   │   └── [charles-webapp, charles-api, charles-db]                │ │
│  │   ├── joshua-workspace                                              │ │
│  │   │   └── [joshua-frontend, joshua-backend]                        │ │
│  │   ├── robert-workspace                                              │ │
│  │   │   └── [robert-app1, robert-app2]                               │ │
│  │   ├── sharmaine-workspace                                           │ │
│  │   │   └── [sharmaine-service, sharmaine-worker]                    │ │
│  │   ├── daniel-workspace                                              │ │
│  │   │   └── [daniel-api, daniel-frontend]                            │ │
│  │   ├── jett-workspace                                                │ │
│  │   │   └── [jett-app, jett-db]                                      │ │
│  │   └── thon-workspace                                                │ │
│  │       └── [thon-webapp, thon-service]                              │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │            ECR Repository: eks-workshop-apps (Shared)                │ │
│  │                                                                      │ │
│  │   Images (Tagged by Username):                                      │ │
│  │   ├── charles-webapp:v1, charles-webapp:v2, charles-api:v1         │ │
│  │   ├── joshua-frontend:v1, joshua-backend:v1                        │ │
│  │   ├── robert-app1:v1, robert-app2:v1                               │ │
│  │   ├── sharmaine-service:v1, sharmaine-worker:v1                    │ │
│  │   ├── daniel-api:v1, daniel-frontend:v2                            │ │
│  │   ├── jett-app:v1, jett-db:v1                                      │ │
│  │   └── thon-webapp:v1, thon-service:v1                              │ │
│  │                                                                      │ │
│  │   URI: <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/          │ │
│  │        eks-workshop-apps                                            │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │            IAM Roles & Access                                        │ │
│  │                                                                      │ │
│  │   ┌────────────────────────────────────────────┐                   │ │
│  │   │  EKS Cluster Service Role                   │                   │ │
│  │   │  Used by: EKS Control Plane                 │                   │ │
│  │   │  Policy: AmazonEKSClusterPolicy             │                   │ │
│  │   │  Purpose: Manage AWS resources for cluster  │                   │ │
│  │   └────────────────────────────────────────────┘                   │ │
│  │                                                                      │ │
│  │   ┌────────────────────────────────────────────┐                   │ │
│  │   │  EKS Node Instance Role                     │                   │ │
│  │   │  Used by: Worker Nodes (EC2)                │                   │ │
│  │   │  Policies:                                  │                   │ │
│  │   │    - AmazonEKSWorkerNodePolicy              │                   │ │
│  │   │    - AmazonEKS_CNI_Policy                   │                   │ │
│  │   │    - AmazonEC2ContainerRegistryReadOnly     │                   │ │
│  │   │  Purpose: Join cluster, pull images         │                   │ │
│  │   └────────────────────────────────────────────┘                   │ │
│  │                                                                      │ │
│  │   ┌────────────────────────────────────────────┐                   │ │
│  │   │  Participant IAM Users (7 users)            │                   │ │
│  │   │  Users: eks-charles, eks-joshua, ...        │                   │ │
│  │   │  Policy: EKSWorkshopPolicy                  │                   │ │
│  │   │  RBAC: Mapped to system:masters (admin)    │                   │ │
│  │   │  Can: Full cluster access (create/delete)   │                   │ │
│  │   └────────────────────────────────────────────┘                   │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘

Access Flow:
Participant → AWS IAM Auth → kubectl → EKS API → Nodes → Pods (in namespace)
```

---

## 🆚 Shared vs Individual Setup Comparison

### Individual Setup (Activity 3)

```
Participant 1:
└── VPC 1 (10.0.0.0/16)
    └── EKS Cluster 1
        └── 2 Nodes
            └── Only Participant 1's apps

Participant 2:
└── VPC 2 (10.0.0.0/16)
    └── EKS Cluster 2
        └── 2 Nodes
            └── Only Participant 2's apps

... (5 more identical setups)

Total Resources:
├── 7 VPCs
├── 7 EKS Clusters
├── 14 EC2 Nodes
└── 7 ECR Repositories

Total Cost: 7 × $95 = $665/month
```

### Shared Setup (Activity 3-1 - This Activity)

```
All 7 Participants:
└── VPC 1 (10.0.0.0/16) [SHARED]
    └── EKS Cluster 1 [SHARED]
        └── 2-10 Nodes [SHARED - can scale]
            └── All participants' apps (isolated by namespace)

Total Resources:
├── 1 VPC
├── 1 EKS Cluster
├── 2 EC2 Nodes (initially)
└── 1 ECR Repository (shared with tagging)

Total Cost: $95/month
Savings: $570/month (85% cheaper!)
```

---

## 🧩 Component Details

### 1. Shared VPC

**CIDR:** 10.0.0.0/16 (65,536 IP addresses)

**Why Shared:**
- One network for all participants
- Reduces complexity
- Lowers cost (no multiple IGWs, route tables)
- Real-world pattern (companies share VPCs across teams)

**What This Means for You:**
- All participants' pods run in same network
- Pods can communicate across namespaces (unless restricted)
- Network policies can add isolation if needed

---

### 2. Public Subnets (2×)

**Subnet A:** 10.0.1.0/24 (256 IPs) in ap-southeast-1a
**Subnet B:** 10.0.2.0/24 (256 IPs) in ap-southeast-1b

**Why 2 Subnets:**
- High availability across availability zones
- If AZ-1a fails, AZ-1b continues
- EKS requirement (minimum 2 AZs)

**Why Public:**
- Direct internet access (no NAT Gateway cost)
- Nodes can pull container images
- Applications can receive traffic
- Good for learning/development

**Production Difference:**
- Would use private subnets + NAT Gateway
- Public subnets only for load balancers
- More secure but more expensive

---

### 3. EKS Control Plane (Shared)

**Cluster Name:** shared-workshop-cluster
**Managed by:** AWS (you don't see or manage these servers)
**High Availability:** Automatically spans 3 AZs

**Components:**

**API Server:**
- Entry point for all kubectl commands
- ALL 7 participants connect here
- Handles authentication and authorization
- Port 443 (HTTPS)

**Scheduler:**
- Decides which node runs which pod
- Considers resources, constraints, affinity
- Works for all participants' workloads

**Controller Manager:**
- Maintains desired state
- Auto-restarts failed pods
- Manages deployments, replicasets
- Works for everyone's resources

**etcd:**
- Database storing cluster state
- Contains all resources from all namespaces
- Automatically backed up by AWS

**Cost:** $0.10/hour = $72/month (fixed, regardless of users)

---

### 4. Worker Nodes (Shared)

**Initial Setup:**
- 2× t3.medium Spot instances
- Distributed across both availability zones
- 2 vCPU, 4GB RAM each
- 20GB gp3 storage each

**Shared Usage:**
- ALL participants' pods run on these same nodes
- Kubernetes scheduler distributes pods
- Resource limits prevent one user hogging resources

**Scaling:**
- Configured: min=2, max=10, desired=2
- Participants can add node groups
- Coordinate before scaling to avoid surprise costs!

**What Runs on Nodes:**
- System pods (kube-proxy, aws-node, coredns)
- Participant workloads (from all namespaces)
- Each node can host ~10-15 small pods

**Resource Capacity (Per Node):**
```
CPU: 2 vCPUs
├── System reserved: ~0.2 vCPU
├── System pods: ~0.1 vCPU
└── Available for apps: ~1.7 vCPU

Memory: 4 GB
├── System reserved: ~0.5 GB
├── System pods: ~0.3 GB
└── Available for apps: ~3.2 GB
```

**Total Cluster (2 nodes):**
```
Available for all 7 participants:
├── CPU: ~3.4 vCPU
├── Memory: ~6.4 GB
└── ~20-30 small pods total

Per participant (if shared equally):
├── CPU: ~0.5 vCPU
├── Memory: ~900 MB
└── ~3-4 small pods
```

---

### 5. Namespace Isolation

**System Namespaces (Pre-existing - Don't Touch!):**

**default:**
- Default namespace for resources without namespace
- Best practice: Don't use for participant work

**kube-system:**
- Kubernetes system components
- Contains kube-proxy, coredns, aws-node
- ⚠️ NEVER delete or modify!

**kube-public:**
- Publicly readable cluster information
- Used for cluster discovery

**kube-node-lease:**
- Node heartbeat information
- Performance optimization for node status

---

**Participant Namespaces (You Create These):**

Each participant should create personal namespace(s):

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: charles-workspace
  labels:
    owner: charles
    team: workshop
```

**Namespace Benefits:**
- Logical isolation of resources
- Organize your applications
- Apply resource quotas (optional)
- Clean up easily (delete namespace = delete all your apps)

**Namespace Limitations:**
- ⚠️ NOT security boundaries (without network policies)
- All participants can see all namespaces
- All participants can access resources in any namespace
- Communication and trust required!

---

### 6. Shared ECR Repository

**Repository Name:** eks-workshop-apps
**URI:** `<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps`

**Tagging Convention:**
```
Format: <username>-<appname>-<version>

Examples:
- charles-webapp-v1
- charles-webapp-v2
- charles-api-v1
- joshua-frontend-v1
- robert-backend-v2
```

**Why One Shared Repository:**
- Simpler permission management
- Lower cost (charged per repository)
- Easy to see all workshop images
- Teaches tagging discipline

**Best Practices:**
- Always prefix with your username
- Use semantic versioning (v1, v2, v3)
- Document what each image contains
- Clean up old images

---

### 7. IAM and RBAC Permissions

**Two Permission Systems:**

**IAM (AWS Level):**
- Controls access to AWS APIs
- Participants have EKSWorkshopPolicy
- Grants: EKS, EC2, ECR, CloudFormation, etc.
- Allows cluster access and node management

**RBAC (Kubernetes Level):**
- Controls access within the cluster
- Participants mapped to `system:masters` group
- Full administrative access to all resources
- Can create/delete anything in cluster

**Permission Flow:**
```
1. Participant runs: kubectl get pods
2. IAM checks: Does user have eks:DescribeCluster?
3. kubectl connects to API server
4. API server checks: What RBAC role does user have?
5. RBAC: system:masters = full access
6. API server returns pod list
```

**Security Implications:**

⚠️ **Full Admin Access Means:**
- You CAN delete the entire cluster
- You CAN delete other participants' resources
- You CAN consume all cluster resources
- You CAN modify system components

**Why This Setup:**
- Learning environment (not production)
- Trust-based model
- Full hands-on experience
- Teaches responsibility

**Production Alternative:**
- Create namespace-specific RBAC roles
- Limit users to their own namespaces
- Separate node management permissions
- Audit all actions with CloudTrail

---

## 📊 Resource Distribution

### How Resources Are Shared

**CPU and Memory:**
```
Total Available: 3.4 vCPU, 6.4 GB RAM

Without Resource Limits:
└── First-come, first-served
    └── One user could consume everything!

With Resource Limits (Recommended):
└── Each pod specifies requests and limits
    └── Scheduler ensures fair distribution
```

**Example Pod with Limits:**
```yaml
resources:
  requests:     # Guaranteed resources
    cpu: 100m
    memory: 128Mi
  limits:       # Maximum allowed
    cpu: 200m
    memory: 256Mi
```

---

### Storage Distribution

**Node Storage (EBS):**
- Each node: 20GB gp3
- Shared by all pods on that node
- System takes ~4GB
- Container images take ~2GB per node
- Remaining ~14GB for pod data

**Persistent Volumes (If Used):**
- Created separately from nodes
- Can be provisioned by any participant
- Charged separately ($0.08/GB/month)
- Should be deleted when not needed

---

## 💰 Detailed Cost Breakdown

### Fixed Costs (Always Running)

```
EKS Control Plane:
├── $0.10/hour
├── $2.40/day
├── $72/month
└── Shared by all 7 participants = $10.29/person/month
```

### Variable Costs (Based on Usage)

```
Worker Nodes (2× t3.medium Spot):
├── On-Demand: $0.0416/hour each = $60/month for both
├── Spot (70% off): $0.0125/hour each = $18/month for both
└── Shared by 7 participants = $2.57/person/month

EBS Volumes (2× 20GB gp3):
├── $0.08/GB/month
├── 40GB total = $3.20/month
└── Shared by 7 participants = $0.46/person/month

ECR Storage:
├── $0.10/GB/month
├── Estimated 5GB total images = $0.50/month
└── Shared by 7 participants = $0.07/person/month

Data Transfer:
├── Inbound: Free
├── Outbound: $0.09/GB (first 1GB free/month)
├── Estimated: ~$0.50/month
└── Shared by 7 participants = $0.07/person/month

CloudWatch Logs (Optional):
├── $0.50/GB ingested
├── $0.03/GB stored
├── Short retention = ~$1-2/month
└── Shared by 7 participants = $0.14-0.29/person/month
```

### Total Costs

```
Total Cluster Cost:
├── Fixed: $72/month
├── Variable: $23/month
└── Total: ~$95/month

Per Participant (if split equally):
└── $95 ÷ 7 = $13.57/month/person

For 4-hour Workshop:
├── Total: $0.13/hour × 4 = $0.52
└── Per person: $0.52 ÷ 7 = $0.07/person!
```

### Cost Comparison

```
Individual Setup (Activity 3):
├── 7 clusters × $95 = $665/month
└── 4-hour workshop: $3.64 total

Shared Setup (This Activity):
├── 1 cluster = $95/month
└── 4-hour workshop: $0.52 total

Savings:
├── Monthly: $570 (85% cheaper!)
└── 4-hour workshop: $3.12 (85% cheaper!)
```

---

## 🔄 Data Flow Examples

### 1. Participant Deploys Application

```
1. Charles → kubectl apply -f webapp.yaml -n charles-workspace
   ↓
2. kubectl → AWS IAM authentication (validates eks-charles user)
   ↓
3. Sends HTTPS request to EKS API Server (port 443)
   ↓
4. API Server → Authenticates via aws-auth ConfigMap
   ↓
5. API Server → Checks RBAC (system:masters = allowed)
   ↓
6. API Server → Validates YAML, stores in etcd
   ↓
7. Controller Manager → Sees new Deployment
   ↓
8. Creates ReplicaSet with 2 pods
   ↓
9. Scheduler → Assigns pods to nodes (node 1 and node 2)
   ↓
10. kubelet on each node → Pulls image from ECR
    ↓
11. kubelet → Starts containers
    ↓
12. Pods running in charles-workspace namespace!
```

---

### 2. Participant Accesses Another's Application

```
Scenario: Joshua wants to call Charles's API

1. Joshua's pod (in joshua-workspace)
   ↓
2. DNS lookup: charles-api.charles-workspace.svc.cluster.local
   ↓
3. CoreDNS resolves to ClusterIP (e.g., 10.100.23.45)
   ↓
4. Packet sent to ClusterIP
   ↓
5. kube-proxy (iptables) on local node routes to charles-api pod
   ↓
6. Packet reaches Charles's pod (could be on any node)
   ↓
7. Charles's API responds
   ↓
8. Response flows back to Joshua's pod

Note: This works because there's NO network isolation between namespaces!
```

---

### 3. External User Accesses Application

```
1. User → http://54.123.45.67:30080 (NodePort service)
   ↓
2. Internet → AWS Internet Gateway
   ↓
3. Routes to VPC
   ↓
4. Security Group check (port 30080 allowed?)
   ↓
5. Reaches Node's public IP
   ↓
6. kube-proxy (iptables) routes to target pod
   ↓
7. Pod could be in ANY namespace (charles, joshua, etc.)
   ↓
8. Application processes request
   ↓
9. Response flows back through same path
```

---

### 4. Participant Pushes Image to ECR

```
1. Charles → docker build -t myapp .
   ↓
2. Docker builds image locally
   ↓
3. Charles → aws ecr get-login-password | docker login
   ↓
4. AWS CLI authenticates with IAM (eks-charles credentials)
   ↓
5. Returns temporary ECR auth token
   ↓
6. Docker stores auth token
   ↓
7. Charles → docker tag myapp <ecr-uri>:charles-myapp-v1
   ↓
8. Image tagged with naming convention
   ↓
9. Charles → docker push <ecr-uri>:charles-myapp-v1
   ↓
10. Docker uploads layers to ECR
    ↓
11. ECR stores image in eks-workshop-apps repository
    ↓
12. All participants can now pull: charles-myapp-v1
```

---

## ⚡ Coordination Patterns

### Best Practices for Shared Environment

**1. Naming Conventions:**
```
Namespaces:      <name>-workspace (charles-workspace)
Deployments:     <name>-<app> (charles-webapp)
Services:        <name>-<app>-svc (charles-webapp-svc)
Node Groups:     <name>-nodes (charles-nodes)
ECR Images:      <name>-<app>-<version> (charles-webapp-v1)
```

**2. Communication Protocol:**
- Announce in team chat before:
  - Creating node groups
  - Scaling beyond 4 nodes total
  - Deleting node groups
  - Creating large deployments (>5 replicas)

**3. Resource Etiquette:**
```
DO:
✅ Set resource requests/limits on pods
✅ Use appropriate replica counts (2-3 for learning)
✅ Delete resources when done testing
✅ Monitor cluster capacity
✅ Ask before scaling nodes

DON'T:
❌ Create 20 replicas of your app
❌ Deploy without resource limits
❌ Delete others' resources
❌ Use all available capacity
❌ Leave resources running overnight
```

**4. Conflict Avoidance:**
- Use personal namespaces
- Prefix all resources with your name
- Check cluster capacity before deploying
- Coordinate node group changes
- Clean up after testing

---

## 🎯 Success Criteria

Your shared cluster is working correctly when:

```
Infrastructure (Root Setup):
✅ VPC with 2 subnets exists
✅ Internet Gateway attached
✅ Security groups configured
✅ EKS cluster Status = Active
✅ 2 worker nodes Ready
✅ ECR repository created
✅ All 7 participants can connect

Participant Usage:
✅ Each participant can kubectl get nodes
✅ Each has created personal namespace
✅ Apps deployed in personal namespaces
✅ Images pushed to ECR with name prefixes
✅ No resource conflicts
✅ Good communication among participants
```

---

## 📚 What You're Learning

### Technical Skills

**Kubernetes Multi-Tenancy:**
- Namespace isolation
- Resource quotas (optional)
- RBAC permissions
- Network policies (optional)

**Collaboration:**
- Working in shared infrastructure
- Coordinating resource usage
- Communication protocols
- Conflict resolution

**AWS Skills:**
- Shared VPC patterns
- IAM authentication with EKS
- ECR image management
- Cost optimization

### Real-World Parallels

This setup mirrors real production environments:

```
Your Workshop:                  Real Company:
├── Shared cluster             ├── Shared cluster per environment
├── 7 participants             ├── 10-100 developers
├── Personal namespaces        ├── Team namespaces
├── Coordinate scaling         ├── Capacity planning
├── Communication required     ├── Infrastructure team coordination
└── Cost awareness             └── FinOps practices
```

---

## 🚀 Next Steps

After understanding this architecture:

1. **Root:** Follow ROOT-SETUP guides to build this infrastructure
2. **Participants:** Follow PARTICIPANT-GUIDES to use the cluster
3. **Everyone:** Read SAFETY-GUIDELINES.md
4. **Everyone:** Practice good communication!

---

## 🔗 Related Documents

- [README.md](README.md) - Start here for overview
- [SAFETY-GUIDELINES.md](SAFETY-GUIDELINES.md) - Critical reading!
- [ROOT-SETUP/](ROOT-SETUP/) - Admin setup guides
- [PARTICIPANT-GUIDES/](PARTICIPANT-GUIDES/) - User guides
- [REFERENCE/](REFERENCE/) - Command references and troubleshooting

---

**Remember:** This is a SHARED environment. Your actions affect 6 other people. Be thoughtful, communicate, and have fun learning together! 🤝

