# Activity 3 Architecture - What You're Building

This document explains the architecture you'll manually create through the AWS Console.

---

## 🏗️ Complete Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│              AWS Account (ap-southeast-1)                            │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                   VPC: 10.0.0.0/16                             │ │
│  │                                                                │ │
│  │  ┌───────────────────┐         ┌───────────────────┐         │ │
│  │  │ Public Subnet A   │         │ Public Subnet B   │         │ │
│  │  │ 10.0.1.0/24       │         │ 10.0.2.0/24       │         │ │
│  │  │ AZ: a             │         │ AZ: b             │         │ │
│  │  │                   │         │                   │         │ │
│  │  │  ┌─────────────┐  │         │  ┌─────────────┐  │         │ │
│  │  │  │  Node 1     │  │         │  │  Node 2     │  │         │ │
│  │  │  │  t3.medium  │  │         │  │  t3.medium  │  │         │ │
│  │  │  │  Spot       │  │         │  │  Spot       │  │         │ │
│  │  │  │  20GB gp3   │  │         │  │  20GB gp3   │  │         │ │
│  │  │  │             │  │         │  │             │  │         │ │
│  │  │  │  Pod: Todo  │  │         │  │  Pod: Todo  │  │         │ │
│  │  │  └─────────────┘  │         │  └─────────────┘  │         │ │
│  │  │                   │         │                   │         │ │
│  │  │  10.0.1.100       │         │  10.0.2.100       │         │ │
│  │  └───────────────────┘         └───────────────────┘         │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │           Internet Gateway                                │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │           Route Tables                                    │ │ │
│  │  │  0.0.0.0/0 → Internet Gateway                            │ │ │
│  │  │  10.0.0.0/16 → Local                                     │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  │                                                                │ │
│  │  ┌──────────────────────────────────────────────────────────┐ │ │
│  │  │           Security Groups                                 │ │ │
│  │  │  - Cluster SG (port 443)                                 │ │ │
│  │  │  - Node SG (all ports from cluster + 30000-32767)       │ │ │
│  │  └──────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │           EKS Control Plane (AWS Managed)                      │ │
│  │           Cost: $72/month ($2.40/day)                          │ │
│  │                                                                │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │ │
│  │  │ API      │  │Scheduler │  │Controller│                   │ │
│  │  │ Server   │  │          │  │ Manager  │                   │ │
│  │  └──────────┘  └──────────┘  └──────────┘                   │ │
│  │                                                                │ │
│  │  ┌────────────────────────────────────────┐                  │ │
│  │  │ etcd Database                          │                  │ │
│  │  └────────────────────────────────────────┘                  │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │           IAM Roles                                            │ │
│  │                                                                │ │
│  │  ┌─────────────────────────────────────────┐                 │ │
│  │  │ EKS Cluster Role                        │                 │ │
│  │  │  - AmazonEKSClusterPolicy               │                 │ │
│  │  └─────────────────────────────────────────┘                 │ │
│  │                                                                │ │
│  │  ┌─────────────────────────────────────────┐                 │ │
│  │  │ EKS Node Role                           │                 │ │
│  │  │  - AmazonEKSWorkerNodePolicy            │                 │ │
│  │  │  - AmazonEKS_CNI_Policy                 │                 │ │
│  │  │  - AmazonEC2ContainerRegistryReadOnly   │                 │ │
│  │  └─────────────────────────────────────────┘                 │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  Application: Monolith Todo App                                     │
│  - 1 container (Frontend + Backend combined)                        │
│  - NodePort service (30080)                                         │
│  - Accessible at: http://node-ip:30080                              │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘

Access: Your Machine → Internet → IGW → Node → Pod (Todo App)
```

---

## 🆚 Traditional vs This Setup

### Traditional Single Server

```
Your VPS:
├── Physical/Virtual server
├── One location
├── Manual setup
├── SSH access
├── nginx + App + Database all on one server
└── Single point of failure

Costs: $20-50/month
Scaling: Buy bigger server (vertical only)
Availability: If server down = app down
```

### This EKS Setup

```
AWS EKS:
├── 2 servers (worker nodes)
├── Multiple availability zones
├── Automated management
├── kubectl access
├── Containers for apps
└── Self-healing, auto-restart

Costs: ~$95/month minimum
Scaling: Add more nodes (horizontal)
Availability: If one node down = app still runs
```

---

## 🧩 Components Breakdown

### 1. VPC (Virtual Private Cloud)

**What:** Your isolated network in AWS  
**CIDR:** 10.0.0.0/16 (65,536 IP addresses)  
**Traditional:** Like your data center network

**Why this matters:**
- Isolation from other AWS customers
- Control over IP addressing
- Security boundaries

### 2. Subnets (2x Public)

**Subnet A:** 10.0.1.0/24 in ap-southeast-1a  
**Subnet B:** 10.0.2.0/24 in ap-southeast-1b  
**Traditional:** Like VLANs or network segments

**Why 2 subnets:**
- High availability (multi-AZ)
- If one AZ fails, other continues
- EKS requirement (minimum 2)

**Why public:**
- Direct internet access
- No NAT Gateway needed (saves $32/month)
- Good for learning/development

### 3. Internet Gateway

**What:** Allows VPC resources to access internet  
**Traditional:** Like your router's WAN connection  

**Why this matters:**
- Nodes need to pull container images
- Nodes need to register with EKS
- You need to access your app

### 4. Security Groups

**Control Plane SG:**
- Inbound: Port 443 (HTTPS) from anywhere
- Purpose: kubectl access to API server

**Node SG:**
- Inbound: All from Control Plane SG
- Inbound: Ports 30000-32767 from anywhere (NodePort range)
- Inbound: All from same SG (pod-to-pod)
- Purpose: Allow cluster communication

**Traditional:** Like iptables rules

### 5. IAM Roles

**Cluster Role:**
- Who: EKS Control Plane
- Can do: Manage AWS resources (LB, ENI, SG)
- Policy: AmazonEKSClusterPolicy

**Node Role:**
- Who: Worker Nodes (EC2 instances)
- Can do: Pull images, attach volumes, send logs
- Policies: 
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryReadOnly

**Traditional:** Like service accounts in Linux

### 6. EKS Control Plane

**What:** The "brain" of Kubernetes  
**Managed by:** AWS (you don't see the servers)  
**Cost:** $0.10/hour = $72/month (non-negotiable)

**Components:**
- API Server: Handles kubectl commands
- Scheduler: Decides which node runs which pod
- Controller Manager: Maintains desired state
- etcd: Database for cluster state

**Traditional:** Like your management server

### 7. Worker Nodes (EC2 Instances)

**Type:** t3.medium (2 vCPU, 4GB RAM)  
**Purchase:** Spot instances (70% cheaper!)  
**Count:** 2 nodes  
**Storage:** 20GB gp3 each  
**Cost:** ~$0.025/hour = ~$18/month for both

**What they run:**
- kubelet (Kubernetes agent)
- Container runtime (Docker/containerd)
- Your application pods
- System pods (CNI, kube-proxy)

**Traditional:** Like your application servers

### 8. Application (Monolith Todo)

**Architecture:** Single container  
**Contains:** Frontend (React) + Backend (Node.js)  
**Replicas:** 2 (one per node)  
**Service Type:** NodePort  
**Port:** 30080  
**Access:** http://node-public-ip:30080

**Why monolith here:**
- Simpler to understand
- One container to deploy
- Good starting point
- Activity 4 shows microservices

---

## 📊 Resource Capacity

### Per Node (t3.medium)

```
CPU: 2 vCPUs
├── System reserved: ~0.1 vCPU
├── Kubernetes pods: ~0.1 vCPU
└── Available for apps: ~1.8 vCPU

Memory: 4 GB
├── System reserved: ~0.5 GB
├── Kubernetes pods: ~300 MB
└── Available for apps: ~3.2 GB

Storage: 20 GB gp3
├── OS and system: ~4 GB
├── Container images: ~2 GB
└── Available: ~14 GB
```

### Cluster Total (2 nodes)

```
Total CPU: ~3.6 vCPU available
Total Memory: ~6.4 GB available
Total Storage: ~28 GB available

Can run approximately:
├── 15-20 small pods (100m CPU, 128Mi RAM each)
├── 8-10 medium pods (200m CPU, 256Mi RAM each)
└── 3-5 large pods (500m CPU, 512Mi RAM each)
```

---

## 💰 Cost Breakdown

### Fixed Costs (Always Running)

```
EKS Control Plane: $72/month ($2.40/day)
└── AWS managed, you always pay this
```

### Variable Costs (Based on Configuration)

```
Worker Nodes (2x t3.medium Spot):
├── On-Demand would be: $60/month ($2/day)
├── Spot price: ~$18/month ($0.60/day)
└── Savings: $42/month (70% off!)

EBS Volumes (2x 20GB gp3):
├── $0.08/GB/month
├── 20GB x 2 = 40GB
└── Cost: $3.20/month ($0.11/day)

CloudWatch Logs (API + Audit):
├── Short retention (1 day)
├── Minimal data
└── Cost: ~$1-2/month

Data Transfer:
├── Inbound: Free
├── Outbound: $0.09/GB (first 1GB free)
└── Cost: ~$0.50/month (light usage)

Total: ~$95/month (~$3.15/day)
```

### What We're NOT Using (Saved Costs)

```
❌ NAT Gateway: -$32/month
❌ Application Load Balancer: -$20/month
❌ On-Demand instances: -$42/month
❌ Private subnets: -$0 (but would need NAT)

Total Savings: ~$94/month!
```

---

## 🔄 Data Flow Examples

### User Accesses Todo App

```
1. User → http://54.123.45.67:30080
   ↓
2. Internet → Internet Gateway
   ↓
3. Routes to VPC
   ↓
4. Security Group checks (port 30080 allowed?)
   ↓
5. Reaches Worker Node
   ↓
6. kube-proxy (iptables) routes to Todo Pod
   ↓
7. Todo App processes request
   ↓
8. Response flows back to user
```

### kubectl Command Flow

```
1. You → kubectl get pods
   ↓
2. kubectl → ~/.kube/config (cluster info)
   ↓
3. HTTPS request to EKS API Server (port 443)
   ↓
4. API Server authenticates you
   ↓
5. API Server queries etcd
   ↓
6. Returns pod information
   ↓
7. kubectl displays results
```

### Pod Creation Flow

```
1. You → kubectl apply -f deployment.yaml
   ↓
2. API Server validates YAML
   ↓
3. Stores in etcd
   ↓
4. Controller Manager sees new Deployment
   ↓
5. Creates ReplicaSet
   ↓
6. Scheduler assigns Pod to Node
   ↓
7. kubelet on Node pulls image
   ↓
8. kubelet starts container
   ↓
9. Pod running!
```

---

## ⚡ High Availability Setup

### What We Have

```
Control Plane:
✅ Highly available (AWS managed, multi-AZ)
✅ Automatic failover
✅ You don't manage this

Worker Nodes:
⚠️ 2 nodes in different AZs
✅ Basic redundancy
✅ If one node fails, pods restart on other
❌ Not fully HA (would need 3+ nodes)
❌ Spot instances can be interrupted

Application:
✅ 2 replicas (one per node)
✅ If one pod fails, other handles traffic
✅ Self-healing (auto-restart)
```

### Production Would Have

```
✅ 3+ nodes across 3 AZs
✅ Mix of Spot and On-Demand
✅ Multiple node groups
✅ Pod Disruption Budgets
✅ Application Load Balancer
✅ Auto-scaling enabled
```

---

## 🎯 Success Criteria

Your setup is correct when:

```
VPC:
✅ CIDR: 10.0.0.0/16
✅ 2 public subnets
✅ Internet Gateway attached
✅ Route table configured

Security:
✅ 2 security groups created
✅ Rules allow cluster communication
✅ NodePort range accessible

IAM:
✅ Cluster role exists
✅ Node role exists
✅ Policies attached

Cluster:
✅ Status: ACTIVE
✅ Version: 1.28 or higher
✅ kubectl connected

Nodes:
✅ 2 nodes: Ready
✅ Both in different AZs
✅ System pods: Running

Application:
✅ 2 Todo pods: Running
✅ Service type: NodePort
✅ Accessible from browser
```

---

## 📚 What You're Learning

Through this manual setup, you learn:

1. **VPC Networking**
   - How AWS networking works
   - Public vs private subnets
   - Internet connectivity

2. **IAM Security**
   - Role-based access
   - Service permissions
   - Principle of least privilege

3. **EKS Architecture**
   - Control plane vs data plane
   - How components communicate
   - Kubernetes in AWS

4. **Operational Skills**
   - Resource creation order
   - Dependencies between resources
   - Troubleshooting approaches

**This knowledge helps you:**
- Troubleshoot issues
- Understand eksctl automation
- Design production architectures
- Interview confidently

---

## 🚀 Next Steps

After understanding this architecture:

1. **Create it manually** (following the guides)
2. **Deploy application**
3. **Test and verify**
4. **Clean up** (very important!)
5. **Move to Activity 4** (see automation magic)

---

**Ready to build it?** Start with [01-VPC-Setup.md](01-VPC-Setup.md)!

**Questions about architecture?** Review the component descriptions above.

**Want to see automation?** Complete this activity first, then Activity 4 shows how eksctl does this in one command!

