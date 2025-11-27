# Networking Basics for Cloud

**Estimated Reading Time: 30 minutes**

---

## 🌐 Networking: Traditional vs Cloud

### What You Already Know

```
Traditional Network Setup:
├── Physical router
├── Network switch
├── Firewall appliance
├── Servers with network cards
├── IP addresses
└── Ethernet cables

You understand:
✅ IP addresses (192.168.1.100)
✅ Ports (80, 443, 22)
✅ Firewall rules
✅ DNS
✅ Routing
```

### Cloud Networking

```
Cloud Network Setup:
├── Virtual router (software)
├── Virtual switch (software)
├── Security Groups (software firewall)
├── Virtual machines
├── IP addresses (same!)
└── Software-defined networking

Same concepts, virtualized!
```

---

## 🔢 IP Addresses and CIDR Notation

### IP Address Basics (Review)

```
IPv4 Address: 10.0.1.50
├── 4 numbers (octets)
├── Each: 0-255
└── Example: 10.0.1.50

Traditional:             Cloud:
Static IP           →    Elastic IP
DHCP                →    Auto-assign
Private subnet      →    Private subnet
NAT                 →    NAT Gateway
```

### CIDR Notation (Important for Cloud!)

**CIDR = Classless Inter-Domain Routing**

```
Notation: 10.0.0.0/16

Breaking it down:
├── 10.0.0.0 = Network address
└── /16 = Subnet mask
    └── First 16 bits are network
    └── Last 16 bits are hosts
```

**Common CIDR blocks:**

```
/32 = 1 IP address
Example: 10.0.1.50/32
└── Just one specific IP

/24 = 256 IP addresses
Example: 10.0.1.0/24
├── Network: 10.0.1.0
├── Usable: 10.0.1.1 - 10.0.1.254
├── Broadcast: 10.0.1.255
└── Total usable: 251 (AWS reserves 5)

/16 = 65,536 IP addresses
Example: 10.0.0.0/16
├── Range: 10.0.0.0 - 10.0.255.255
└── Can create many /24 subnets

/8 = 16,777,216 IP addresses
Example: 10.0.0.0/8
└── Range: 10.0.0.0 - 10.255.255.255
```

**Quick reference:**

| CIDR | Addresses | Use Case |
|------|-----------|----------|
| /32 | 1 | Single IP |
| /28 | 16 | Tiny subnet |
| /24 | 256 | Standard subnet |
| /20 | 4,096 | Medium network |
| /16 | 65,536 | Large VPC |
| /8 | 16M | Huge range |

**Traditional equivalent:**

```
Traditional:                    CIDR:
Subnet mask 255.255.255.0  →    /24
Subnet mask 255.255.0.0    →    /16
Subnet mask 255.0.0.0      →    /8
```

**CIDR calculator trick:**

```
/24 = 2^(32-24) = 2^8 = 256 addresses
/16 = 2^(32-16) = 2^16 = 65,536 addresses
/20 = 2^(32-20) = 2^12 = 4,096 addresses

Formula: 2^(32 - CIDR) = number of addresses
```

---

## 🏗️ VPC Networking Architecture

### Our EKS Cluster Network

```
Internet (0.0.0.0/0)
   │
   ▼
┌────────────────────────────────────────────────┐
│          Internet Gateway                      │
└────────────────────────────────────────────────┘
   │
   ▼
┌────────────────────────────────────────────────┐
│     VPC: 10.0.0.0/16 (65,536 IPs)            │
│                                                │
│  ┌──────────────────┐  ┌──────────────────┐  │
│  │  Public Subnet A │  │  Public Subnet B │  │
│  │  10.0.1.0/24     │  │  10.0.2.0/24     │  │
│  │  (256 IPs)       │  │  (256 IPs)       │  │
│  │                  │  │                  │  │
│  │  AZ: a           │  │  AZ: b           │  │
│  │                  │  │                  │  │
│  │  ┌──────────┐    │  │  ┌──────────┐    │  │
│  │  │ Node 1   │    │  │  │ Node 2   │    │  │
│  │  │ 10.0.1.10│    │  │  │ 10.0.2.10│    │  │
│  │  └──────────┘    │  │  └──────────┘    │  │
│  └──────────────────┘  └──────────────────┘  │
└────────────────────────────────────────────────┘
```

### IP Address Assignment

```
VPC: 10.0.0.0/16
│
├── Subnet A: 10.0.1.0/24
│   ├── AWS Reserved (5 IPs):
│   │   ├── 10.0.1.0   = Network address
│   │   ├── 10.0.1.1   = VPC router
│   │   ├── 10.0.1.2   = DNS server
│   │   ├── 10.0.1.3   = Future use
│   │   └── 10.0.1.255 = Broadcast
│   │
│   └── Usable (251 IPs):
│       ├── 10.0.1.4 - 10.0.1.254
│       ├── Node: 10.0.1.10
│       ├── Pods: 10.0.1.20-100
│       └── Others: Available
│
└── Subnet B: 10.0.2.0/24
    └── Same pattern
```

---

## 🚪 Public vs Private Subnets

### Public Subnet

**Has route to Internet Gateway = Can access internet directly**

```
Public Subnet: 10.0.1.0/24
│
├── Route Table:
│   ├── 10.0.0.0/16 → local
│   └── 0.0.0.0/0 → Internet Gateway
│
├── Resources get public IP
├── Can be accessed from internet
└── Use case: Web servers, load balancers

Example:
EC2 in public subnet:
├── Private IP: 10.0.1.10
├── Public IP: 54.123.45.67
└── Can access internet directly
```

### Private Subnet

**No route to Internet Gateway = Cannot access internet directly**

```
Private Subnet: 10.0.3.0/24
│
├── Route Table:
│   ├── 10.0.0.0/16 → local
│   └── 0.0.0.0/0 → NAT Gateway
│
├── Resources get private IP only
├── Cannot be accessed from internet
├── Outbound via NAT Gateway
└── Use case: Databases, backend servers

Example:
EC2 in private subnet:
├── Private IP: 10.0.3.10
├── Public IP: None
└── Internet access via NAT Gateway
```

**Traditional equivalent:**

```
Traditional:              AWS:
DMZ (public servers)  →   Public Subnet
Internal network      →   Private Subnet
NAT/Proxy server      →   NAT Gateway
```

### NAT Gateway

**Allows private subnet to access internet (outbound only)**

```
Internet
   ↑
   │ (outbound only)
┌──────────────┐
│ NAT Gateway  │ (in public subnet)
└──────────────┘
   ↑
   │
┌──────────────────┐
│ Private Subnet   │
│  EC2 instances   │
└──────────────────┘

Cost: $32/month + data transfer
```

**For our training:** We skip NAT Gateway (use public subnets only)

---

## 🔥 Security Groups (Firewall)

### Stateful Firewall

```
Security Group = Stateful firewall

Stateful means:
├── If you allow inbound, response is automatic
└── If you allow outbound, response is automatic

Example:
Allow inbound port 80
├── Request comes in on port 80 ✅
└── Response goes out automatically ✅
    (No need to allow outbound)
```

**Traditional equivalent:**

```bash
# iptables (also stateful)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# AWS Security Group does this automatically!
```

### Security Group Rules

```
Security Group: web-server-sg

Inbound Rules:
┌──────┬──────────┬────────────┬─────────────┐
│ Type │ Protocol │ Port Range │   Source    │
├──────┼──────────┼────────────┼─────────────┤
│ HTTP │   TCP    │     80     │ 0.0.0.0/0   │
│ HTTPS│   TCP    │    443     │ 0.0.0.0/0   │
│ SSH  │   TCP    │     22     │ My IP only  │
└──────┴──────────┴────────────┴─────────────┘

Reads as:
- Allow HTTP from anywhere
- Allow HTTPS from anywhere
- Allow SSH from my IP only

Outbound Rules:
┌──────────┬────────────┬─────────────┐
│ Protocol │ Port Range │ Destination │
├──────────┼────────────┼─────────────┤
│   All    │    All     │  0.0.0.0/0  │
└──────────┴────────────┴─────────────┘

Default: Allow all outbound
```

### Security Group Sources

```
Source types:

1. CIDR Block:
   └── 0.0.0.0/0 = Anywhere
   └── 10.0.0.0/16 = VPC
   └── 203.0.113.0/24 = Specific network

2. Another Security Group:
   └── sg-12345678 = Other SG
   └── Allows communication between SGs

3. Prefix List:
   └── pl-12345678 = S3 endpoints
```

**Example for EKS:**

```
Node Security Group:
├── Inbound:
│   ├── Port 443 from Control Plane SG
│   ├── Ports 1025-65535 from Control Plane SG
│   ├── All traffic from same SG (node-to-node)
│   └── Ports 30000-32767 from 0.0.0.0/0
│
└── Outbound:
    └── All traffic to anywhere
```

---

## 🗺️ Routing

### Route Tables

**Define where network traffic goes.**

```
Route Table: Public
┌───────────────┬──────────────────┐
│  Destination  │      Target      │
├───────────────┼──────────────────┤
│ 10.0.0.0/16   │      local       │ ← Internal VPC
│ 0.0.0.0/0     │ Internet Gateway │ ← Everything else
└───────────────┴──────────────────┘

How it works:
Traffic to 10.0.x.x → Goes to VPC (local)
Traffic to any other → Goes to Internet Gateway
```

**Traditional equivalent:**

```bash
# Linux routing table
ip route show
10.0.0.0/16 dev eth0 scope link
default via 10.0.0.1 dev eth0  # = 0.0.0.0/0

# Same concept!
```

### Routing Priority

```
Most specific route wins:

Routes:
├── 10.0.1.0/24 → Subnet A
├── 10.0.0.0/16 → Local
└── 0.0.0.0/0 → Internet Gateway

Traffic to 10.0.1.50:
├── Matches 10.0.1.0/24 ✅ (most specific)
├── Matches 10.0.0.0/16 ✓
└── Matches 0.0.0.0/0 ✓
    
    → Goes to Subnet A (most specific wins)
```

---

## 🔌 Ports and Protocols

### Common Ports (Review)

```
Well-known ports:
├── 20/21: FTP
├── 22: SSH
├── 25: SMTP
├── 53: DNS
├── 80: HTTP
├── 443: HTTPS
├── 3000: Node.js (common)
├── 3306: MySQL
├── 5432: PostgreSQL
└── 6379: Redis
```

### Kubernetes Ports

```
EKS Control Plane:
└── 443: API Server

Worker Nodes:
├── 22: SSH (optional)
├── 1025-65535: Kubelet communication
├── 10250: Kubelet API
└── 30000-32767: NodePort services

Pods:
└── Any port (containerPort)
```

**NodePort Range:**

```
NodePort: 30000-32767

Example:
Service NodePort: 30080
├── Access: http://node-ip:30080
└── Routes to: Pod port 80

Like port forwarding:
Router :30080 → Server :80
```

---

## 🌐 DNS in Kubernetes

### Cluster DNS

```
Kubernetes provides internal DNS:

Service: backend-service
├── Full DNS: backend-service.default.svc.cluster.local
├── Short (same namespace): backend-service
└── With namespace: backend-service.default

From another pod:
curl http://backend-service:3000
└── DNS resolves to service ClusterIP
```

**DNS hierarchy:**

```
cluster.local (cluster domain)
└── svc (services)
    └── default (namespace)
        └── backend-service (service name)
            └── Resolves to: 10.100.50.10 (ClusterIP)
```

---

## 📊 Network Flow Example

### Complete Request Flow

```
1. User → http://node-ip:30080
   │
   ▼
2. Internet Gateway
   │
   ▼
3. VPC Router (10.0.0.0/16)
   │
   ▼
4. Security Group check
   ├─ Port 30080 allowed? ✅
   │
   ▼
5. Worker Node (10.0.1.10)
   │
   ▼
6. kube-proxy (iptables)
   ├─ NodePort 30080 → Service
   │
   ▼
7. Service (ClusterIP: 10.100.50.10)
   ├─ Load balance to Pod
   │
   ▼
8. Pod (10.0.1.20:80)
   ├─ Container processes request
   │
   ▼
9. Response flows back
   └─ Pod → Service → Node → IGW → User
```

### Pod-to-Pod Communication

```
Frontend Pod → Backend Pod

1. Frontend: Call http://backend-service:3000
   │
   ▼
2. CoreDNS resolves backend-service
   └─ Returns: 10.100.50.10 (Service ClusterIP)
   │
   ▼
3. Traffic to 10.100.50.10:3000
   │
   ▼
4. Service load-balances to backend Pod
   └─ Selects: 10.0.2.15:3000
   │
   ▼
5. Direct Pod-to-Pod communication
   └─ Within VPC, no internet involved
```

---

## 🔐 Network Security Best Practices

### Principle of Least Privilege

```
❌ Bad: Allow all traffic
Security Group:
└── 0.0.0.0/0 on all ports

✅ Good: Allow only needed
Security Group:
├── Port 80 from load balancer only
├── Port 443 from load balancer only
└── Port 22 from your IP only
```

### Defense in Depth

```
Multiple layers of security:

Layer 1: VPC
└── Isolated network

Layer 2: Subnets
└── Separate public/private

Layer 3: Security Groups
└── Instance-level firewall

Layer 4: Network ACLs (optional)
└── Subnet-level firewall

Layer 5: Application
└── Application-level auth
```

---

## ✅ Key Takeaways

### Networking Concepts:
- **CIDR**: IP address ranges (10.0.0.0/16)
- **Subnets**: Subdivisions of VPC
- **Public/Private**: Internet access or not
- **Security Groups**: Stateful firewall rules
- **Route Tables**: Where traffic goes
- **NAT Gateway**: Private subnet internet access

### For EKS:
- VPC: Your isolated network
- Multiple AZs: High availability
- Public subnets: Simpler, cheaper (our setup)
- Security Groups: Control access
- No NAT Gateway: Cost savings

### Important Numbers:
- VPC: /16 (65,536 IPs)
- Subnet: /24 (256 IPs)
- AWS reserves: 5 IPs per subnet
- NodePort range: 30000-32767

---

## 🚀 Next Steps

You now understand cloud networking fundamentals!

**Next:** [06-IAM-And-Security.md](06-IAM-And-Security.md) - Learn AWS IAM and security!

---

**Remember:** Cloud networking uses same concepts as traditional networking - just virtualized! 🌐

