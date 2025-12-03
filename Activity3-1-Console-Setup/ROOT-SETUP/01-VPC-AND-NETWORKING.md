# Root Setup 01: VPC and Networking

**For:** Workshop Administrator (Root Account)  
**Time:** 30 minutes  
**Cost Impact:** $0 (VPC resources are free)

This is the first step in setting up the shared EKS cluster. You'll create the networking foundation that all participants will use.

---

## 🎯 What You'll Create

- 1× VPC with 10.0.0.0/16 CIDR block
- 2× Public subnets across different availability zones
- 1× Internet Gateway for external access
- 1× Route table configured for internet access
- 2× Security groups (cluster and nodes)

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] AWS Console access as root/admin user
- [ ] Selected region: **ap-southeast-1** (Singapore)
- [ ] Permissions: `ec2:*` or VPC full access

---

## Step 1: Create VPC (5 min)

### Via AWS Console

1. Go to **VPC Console**: https://console.aws.amazon.com/vpc/
2. Ensure you're in **ap-southeast-1** region (top-right corner)
3. Click **Your VPCs** in left sidebar
4. Click **Create VPC** button

**Configure VPC:**
```
Name tag: eks-workshop-vpc
IPv4 CIDR: 10.0.0.0/16
IPv6 CIDR: No IPv6 CIDR block
Tenancy: Default
```

5. Click **Create VPC**
6. **Note the VPC ID** (e.g., vpc-0123456789abcdef0)

### Via AWS CLI

```bash
# Create VPC
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=eks-workshop-vpc},{Key=Project,Value=EKS-Workshop}]' \
    --region ap-southeast-1

# Note the VPC ID from output
```

### Why This Matters

**What is a VPC?**
- Virtual Private Cloud = Your own isolated network in AWS
- Like having your own data center network, but virtual
- Complete control over IP ranges, subnets, routing

**CIDR 10.0.0.0/16:**
- Provides 65,536 IP addresses
- Range: 10.0.0.1 to 10.0.255.254
- Plenty of space for multiple subnets and pods

---

## Step 2: Create Subnets (10 min)

You'll create 2 public subnets in different availability zones for high availability.

### Subnet A (AZ 1a)

**Via AWS Console:**

1. In VPC Console, click **Subnets** in left sidebar
2. Click **Create subnet**

**Configure Subnet A:**
```
VPC ID: <select eks-workshop-vpc>
Subnet name: eks-workshop-public-a
Availability Zone: ap-southeast-1a
IPv4 CIDR block: 10.0.1.0/24
```

3. Click **Create subnet**

**Via AWS CLI:**
```bash
aws ec2 create-subnet \
    --vpc-id <vpc-id> \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ap-southeast-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=eks-workshop-public-a},{Key=Type,Value=public}]' \
    --region ap-southeast-1

# Note the Subnet ID
```

---

### Subnet B (AZ 1b)

**Via AWS Console:**

1. Click **Create subnet** again

**Configure Subnet B:**
```
VPC ID: <select eks-workshop-vpc>
Subnet name: eks-workshop-public-b
Availability Zone: ap-southeast-1b
IPv4 CIDR block: 10.0.2.0/24
```

2. Click **Create subnet**

**Via AWS CLI:**
```bash
aws ec2 create-subnet \
    --vpc-id <vpc-id> \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ap-southeast-1b \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=eks-workshop-public-b},{Key=Type,Value=public}]' \
    --region ap-southeast-1

# Note the Subnet ID
```

---

### Enable Auto-Assign Public IP

Both subnets need to automatically assign public IPs to instances.

**Via AWS Console:**

1. Select **eks-workshop-public-a**
2. Click **Actions** → **Edit subnet settings**
3. Check **Enable auto-assign public IPv4 address**
4. Click **Save**
5. Repeat for **eks-workshop-public-b**

**Via AWS CLI:**
```bash
# Enable for Subnet A
aws ec2 modify-subnet-attribute \
    --subnet-id <subnet-a-id> \
    --map-public-ip-on-launch \
    --region ap-southeast-1

# Enable for Subnet B
aws ec2 modify-subnet-attribute \
    --subnet-id <subnet-b-id> \
    --map-public-ip-on-launch \
    --region ap-southeast-1
```

### Why This Matters

**Why 2 Subnets?**
- **High Availability:** If one AZ fails, cluster continues
- **EKS Requirement:** Minimum 2 subnets in different AZs
- **Load Distribution:** Spreads nodes across physical locations

**Why Different AZs?**
- AZ = Availability Zone = separate data center
- ap-southeast-1a and 1b are physically different buildings
- If one has power/network issue, other is unaffected

**Why Public Subnets?**
- Direct internet access (no NAT Gateway = save $32/month)
- Nodes can pull container images
- Good for learning/development
- Production would use private subnets

---

## Step 3: Create Internet Gateway (3 min)

### Via AWS Console

1. In VPC Console, click **Internet Gateways** in left sidebar
2. Click **Create internet gateway**

**Configure:**
```
Name tag: eks-workshop-igw
```

3. Click **Create internet gateway**
4. Select the newly created IGW
5. Click **Actions** → **Attach to VPC**
6. Select **eks-workshop-vpc**
7. Click **Attach internet gateway**

### Via AWS CLI

```bash
# Create Internet Gateway
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=eks-workshop-igw}]' \
    --region ap-southeast-1

# Note the Internet Gateway ID

# Attach to VPC
aws ec2 attach-internet-gateway \
    --internet-gateway-id <igw-id> \
    --vpc-id <vpc-id> \
    --region ap-southeast-1
```

### Why This Matters

**What is an Internet Gateway?**
- Allows resources in VPC to access the internet
- Like a router connecting your home network to ISP
- Enables:
  - Nodes to download container images
  - kubectl commands to reach API server
  - Applications to serve external users

---

## Step 4: Configure Route Table (5 min)

Route tables determine where network traffic goes.

### Via AWS Console

1. In VPC Console, click **Route Tables** in left sidebar
2. Find the main route table for **eks-workshop-vpc**
   - Look in the "VPC" column
   - Will be named automatically
3. Select that route table
4. Click **Actions** → **Edit routes**
5. Click **Add route**

**Add Internet Route:**
```
Destination: 0.0.0.0/0
Target: Internet Gateway → eks-workshop-igw
```

6. Click **Save changes**

**Associate Subnets:**
1. With route table selected, click **Subnet associations** tab
2. Click **Edit subnet associations**
3. Check both:
   - eks-workshop-public-a
   - eks-workshop-public-b
4. Click **Save associations**

### Via AWS CLI

```bash
# Get route table ID for your VPC
aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --query 'RouteTables[0].RouteTableId' \
    --output text \
    --region ap-southeast-1

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id <route-table-id> \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id <igw-id> \
    --region ap-southeast-1

# Associate with Subnet A
aws ec2 associate-route-table \
    --route-table-id <route-table-id> \
    --subnet-id <subnet-a-id> \
    --region ap-southeast-1

# Associate with Subnet B
aws ec2 associate-route-table \
    --route-table-id <route-table-id> \
    --subnet-id <subnet-b-id> \
    --region ap-southeast-1
```

### Why This Matters

**Route 0.0.0.0/0 → IGW means:**
- All traffic to external destinations (0.0.0.0/0 = anywhere)
- Gets sent to Internet Gateway
- Which routes to internet

**Without this:**
- Nodes couldn't reach internet
- Couldn't pull container images
- Couldn't register with EKS
- Applications couldn't serve users

---

## Step 5: Create Security Groups (7 min)

Security groups act as virtual firewalls.

### Cluster Security Group

**Via AWS Console:**

1. In VPC Console, click **Security Groups** in left sidebar
2. Click **Create security group**

**Configure:**
```
Security group name: eks-workshop-cluster-sg
Description: Security group for EKS cluster control plane
VPC: eks-workshop-vpc
```

**Inbound rules:** Leave empty (EKS manages this)

**Outbound rules:** (default is fine)
- Type: All traffic
- Destination: 0.0.0.0/0

3. Click **Create security group**

**Via AWS CLI:**
```bash
aws ec2 create-security-group \
    --group-name eks-workshop-cluster-sg \
    --description "Security group for EKS cluster control plane" \
    --vpc-id <vpc-id> \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=eks-workshop-cluster-sg}]' \
    --region ap-southeast-1

# Note the Security Group ID
```

---

### Node Security Group

**Via AWS Console:**

1. Click **Create security group** again

**Configure:**
```
Security group name: eks-workshop-node-sg
Description: Security group for EKS worker nodes
VPC: eks-workshop-vpc
```

**Inbound rules - Add these:**

**Rule 1: Node-to-Node Communication**
```
Type: All traffic
Source: Custom → Select eks-workshop-node-sg (self-reference)
Description: Allow nodes to communicate with each other
```

**Rule 2: NodePort Services**
```
Type: Custom TCP
Port range: 30000-32767
Source: 0.0.0.0/0
Description: Allow external access to NodePort services
```

**Outbound rules:** (default all traffic allowed)

2. Click **Create security group**

**Via AWS CLI:**
```bash
# Create the security group
aws ec2 create-security-group \
    --group-name eks-workshop-node-sg \
    --description "Security group for EKS worker nodes" \
    --vpc-id <vpc-id> \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=eks-workshop-node-sg}]' \
    --region ap-southeast-1

# Note the Security Group ID
SG_ID=<node-sg-id>

# Add rule for node-to-node communication
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol -1 \
    --source-group $SG_ID \
    --region ap-southeast-1

# Add rule for NodePort range
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 30000-32767 \
    --cidr 0.0.0.0/0 \
    --region ap-southeast-1
```

### Why This Matters

**Cluster Security Group:**
- Controls access to EKS API server
- EKS automatically manages necessary rules
- We just need to create the group

**Node Security Group:**

**Self-Reference Rule:**
- Pods on different nodes need to talk
- Service mesh, inter-pod communication
- Essential for distributed applications

**NodePort Range 30000-32767:**
- NodePort services expose apps externally
- Port in this range on every node
- Allows participants to access their apps
- Production would use LoadBalancer instead

---

## ✅ Validation

Before proceeding, verify everything is created:

### Via AWS Console

1. **VPCs:** Should see `eks-workshop-vpc` (10.0.0.0/16)
2. **Subnets:** Should see:
   - `eks-workshop-public-a` (10.0.1.0/24, AZ 1a)
   - `eks-workshop-public-b` (10.0.2.0/24, AZ 1b)
   - Both have "Auto-assign public IPv4" = Yes
3. **Internet Gateways:** Should see `eks-workshop-igw` (State: Attached)
4. **Route Tables:** Main route table should have:
   - Route: 10.0.0.0/16 → local
   - Route: 0.0.0.0/0 → eks-workshop-igw
   - Associated with both subnets
5. **Security Groups:** Should see:
   - `eks-workshop-cluster-sg`
   - `eks-workshop-node-sg` (with 2 inbound rules)

### Via AWS CLI

```bash
# Check VPC
aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=eks-workshop-vpc" \
    --query 'Vpcs[0].[VpcId,CidrBlock,State]' \
    --output table \
    --region ap-southeast-1

# Check Subnets
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --query 'Subnets[].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
    --output table \
    --region ap-southeast-1

# Check Internet Gateway
aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=<vpc-id>" \
    --query 'InternetGateways[0].[InternetGatewayId,Attachments[0].State]' \
    --output table \
    --region ap-southeast-1

# Check Security Groups
aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=<vpc-id>" \
    --query 'SecurityGroups[].[GroupId,GroupName]' \
    --output table \
    --region ap-southeast-1
```

### Checklist

- [ ] VPC created with correct CIDR
- [ ] 2 subnets in different AZs
- [ ] Auto-assign public IP enabled on both subnets
- [ ] Internet Gateway created and attached
- [ ] Route table configured with 0.0.0.0/0 → IGW
- [ ] Both subnets associated with route table
- [ ] 2 security groups created
- [ ] Node security group has correct inbound rules

---

## 📝 Save These Values

You'll need these IDs in the next steps. Save them in a text file:

```
VPC ID: vpc-xxxxxxxxxxxxx
Subnet A ID: subnet-xxxxxxxxxxxxx
Subnet B ID: subnet-xxxxxxxxxxxxx
Internet Gateway ID: igw-xxxxxxxxxxxxx
Cluster Security Group ID: sg-xxxxxxxxxxxxx
Node Security Group ID: sg-xxxxxxxxxxxxx
```

---

## 🚨 Troubleshooting

### Issue: Can't create VPC

**Error:** "The maximum number of VPCs has been reached"

**Solution:**
- Default limit is 5 VPCs per region
- Delete unused VPCs or request limit increase
- Check other regions for unused VPCs

---

### Issue: Subnet creation fails

**Error:** "The CIDR ... conflicts with another subnet"

**Solution:**
- Each subnet needs unique CIDR
- Ensure using 10.0.1.0/24 and 10.0.2.0/24
- Don't use overlapping ranges

---

### Issue: Can't add route to Internet Gateway

**Error:** "Route already exists"

**Solution:**
- Check if route already present in table
- Each destination can only have one route
- Delete conflicting route first

---

## 💡 What You've Built

```
AWS Region: ap-southeast-1
│
└── VPC: 10.0.0.0/16
    ├── Subnet A: 10.0.1.0/24 (AZ 1a) [Public]
    ├── Subnet B: 10.0.2.0/24 (AZ 1b) [Public]
    ├── Internet Gateway (attached)
    ├── Route Table
    │   ├── Route: 10.0.0.0/16 → local
    │   └── Route: 0.0.0.0/0 → Internet Gateway
    └── Security Groups
        ├── eks-workshop-cluster-sg
        └── eks-workshop-node-sg
            ├── Allow: All from self
            └── Allow: TCP 30000-32767 from anywhere
```

**This network can now:**
- ✅ Host EKS cluster and nodes
- ✅ Provide high availability (2 AZs)
- ✅ Allow internet access for pulling images
- ✅ Allow external access to applications
- ✅ Enable pod-to-pod communication

---

## 🚀 Next Steps

Network foundation complete! Continue to:

**Next:** [02-IAM-ROLES.md](02-IAM-ROLES.md) - Create IAM roles for cluster and nodes

---

## 📚 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [EKS VPC Requirements](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

