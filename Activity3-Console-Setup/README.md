# Activity 3: Console Setup - Learning the Long Way

Welcome to Activity 3! This is where you get hands-on with AWS. We'll create an EKS cluster using the AWS Console - the "long way" - so you understand what's happening behind the scenes.

---

## 🎯 Learning Objectives

By the end of this activity, you will:

- ✅ Create a complete EKS cluster manually via AWS Console
- ✅ Understand every component (VPC, subnets, IAM roles, etc.)
- ✅ Deploy a simple Todo application
- ✅ Know how to properly clean up resources
- ✅ Understand what eksctl automates (for Activity 4)

---

## ⏱️ Time Estimate

**Total Time: 3-4 hours**

| Step | Task | Time |
|------|------|------|
| 01 | VPC Setup | 30 min |
| 02 | IAM Roles | 20 min |
| 03 | EKS Cluster | 30 min + 20 min wait |
| 04 | Node Group | 20 min + 10 min wait |
| 05 | Deploy Application | 40 min |
| 06 | Testing | 20 min |
| 07 | Cleanup | 30 min |

**Active time:** ~2.5 hours  
**Wait time:** ~30 minutes  
**Cleanup:** ~30 minutes

---

## 💰 Cost Warning

**This activity costs money!**

```
Estimated costs while running:
├── EKS Control Plane: $0.10/hour ($2.40/day)
├── EC2 Nodes (2x t3.medium Spot): $0.025/hour ($0.60/day)
├── EBS Volumes (2x 20GB gp3): $0.11/day
├── Data Transfer: ~$0.05/day
└── Total: ~$3.15/day (~$0.13/hour)

Monthly if left running: ~$95
```

**⚠️ IMPORTANT:** Delete everything when done to stop charges!

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] AWS account with admin access
- [ ] AWS CLI installed and configured
- [ ] kubectl installed
- [ ] Completed Activity 1 (understand concepts)
- [ ] Completed Activity 2 (tools installed)
- [ ] **Budget alert set** ($50/month recommended)

---

## 🏗️ What You'll Build

```
┌─────────────────────────────────────────────┐
│         AWS Account (ap-southeast-1)        │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   VPC: 10.0.0.0/16                    │ │
│  │                                       │ │
│  │   ┌─────────────┐  ┌─────────────┐  │ │
│  │   │ Public      │  │ Public      │  │ │
│  │   │ Subnet A    │  │ Subnet B    │  │ │
│  │   │ 10.0.1.0/24 │  │ 10.0.2.0/24 │  │ │
│  │   │             │  │             │  │ │
│  │   │ ┌─────────┐ │  │ ┌─────────┐ │  │ │
│  │   │ │ Node 1  │ │  │ │ Node 2  │ │  │ │
│  │   │ │t3.medium│ │  │ │t3.medium│ │  │ │
│  │   │ │ (Spot)  │ │  │ │ (Spot)  │ │  │ │
│  │   │ └─────────┘ │  │ └─────────┘ │  │ │
│  │   └─────────────┘  └─────────────┘  │ │
│  │                                       │ │
│  │   ┌───────────────────────────────┐  │ │
│  │   │   Internet Gateway            │  │ │
│  │   └───────────────────────────────┘  │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   EKS Cluster                         │ │
│  │   ├── Control Plane (AWS Managed)     │ │
│  │   ├── IAM Cluster Role                │ │
│  │   └── IAM Node Role                   │ │
│  └───────────────────────────────────────┘ │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │   Deployed Application                │ │
│  │   └── Todo App (Monolith)             │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

---

## 📚 Step-by-Step Guides

### Complete in This Order:

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Start here!
   - Understand what you're building
   - See the complete architecture diagram
   - Compare traditional setup vs EKS

2. **[01-VPC-Setup.md](01-VPC-Setup.md)** - Networking Foundation
   - Create VPC
   - Create 2 public subnets (multi-AZ)
   - Create and attach Internet Gateway
   - Configure route tables
   - Set up security groups

3. **[02-IAM-Roles.md](02-IAM-Roles.md)** - Permissions
   - Create EKS Cluster Service Role
   - Create EKS Node Instance Role
   - Attach required policies
   - Understand what each role does

4. **[03-EKS-Cluster.md](03-EKS-Cluster.md)** - Control Plane
   - Create EKS cluster via console
   - Configure networking
   - Enable logging
   - Wait for cluster to become active (~20 min)

5. **[04-Node-Group.md](04-Node-Group.md)** - Worker Nodes
   - Create managed node group
   - Configure Spot instances
   - Set min/max/desired capacity
   - Wait for nodes to join (~10 min)

6. **[05-Deploy-Application.md](05-Deploy-Application.md)** - Your First App
   - Configure kubectl
   - Deploy monolith Todo app
   - Create NodePort service
   - Verify deployment

7. **[06-Testing.md](06-Testing.md)** - Validation
   - Test application access
   - View logs
   - Scale deployment
   - Verify high availability

8. **[07-CLEANUP.md](07-CLEANUP.md)** - ⚠️ CRITICAL!
   - Delete node group
   - Delete EKS cluster
   - Delete VPC resources
   - Delete IAM roles
   - Verify no resources remain

---

## 💡 Why the Console Way?

### Learning Value

```
Manual Console Setup:
✅ See every component
✅ Understand relationships
✅ Know what can go wrong
✅ Appreciate automation later
✅ Better troubleshooting
✅ Interview knowledge

Automated Setup (Activity 4):
✅ Much faster
✅ Reproducible
✅ Production-ready
✅ Less error-prone
❌ Don't see details
```

**Recommendation:**
- Do Activity 3 ONCE to learn
- Use Activity 4 (eksctl) for everything else

---

## 🎓 Learning Approach

### For Traditional Hosting Users

Throughout the guides, you'll see:

```
🏢 Traditional Way:
   How you'd do this with VPS/dedicated servers

☁️ AWS Way:
   How we do it in the cloud

💡 Why It Matters:
   Benefits of this approach
```

**Example from VPC Setup:**

```
🏢 Traditional: Set up physical network, cables, switches
☁️ AWS: Click buttons, software-defined networking
💡 Benefit: Create network in minutes, not days
```

---

## 🚫 Common Mistakes to Avoid

### 1. Wrong Region

```
❌ Creating resources in different regions
✅ Everything in ap-southeast-1
```

### 2. Skipping Tags

```
❌ No tags = can't track costs
✅ Tag everything: Project=EKS-Training
```

### 3. Wrong Subnet Type

```
❌ Creating private subnets (needs NAT Gateway =$$$)
✅ Use public subnets only (this training)
```

### 4. Forgetting Cleanup

```
❌ Leaving cluster running = $95/month
✅ Delete immediately when done
```

### 5. Insufficient Permissions

```
❌ Limited IAM permissions = creation fails
✅ Need admin or EKS-specific permissions
```

---

## 📊 Progress Tracking

Use this checklist:

### Networking (Step 1)
- [ ] VPC created
- [ ] 2 subnets created
- [ ] Internet Gateway attached
- [ ] Route table configured
- [ ] Security groups created

### IAM (Step 2)
- [ ] Cluster role created
- [ ] Node role created
- [ ] Policies attached

### Cluster (Step 3)
- [ ] EKS cluster created
- [ ] Cluster is ACTIVE
- [ ] kubectl configured

### Nodes (Step 4)
- [ ] Node group created
- [ ] Nodes are Ready
- [ ] 2 nodes running

### Application (Steps 5-6)
- [ ] App deployed
- [ ] Service created
- [ ] App accessible
- [ ] Testing complete

### Cleanup (Step 7)
- [ ] Node group deleted
- [ ] Cluster deleted
- [ ] VPC deleted
- [ ] Roles deleted
- [ ] No remaining resources

---

## 🆘 Help & Troubleshooting

### If Something Goes Wrong

1. **Don't Panic** - Most issues are fixable
2. **Check the Guide** - Each guide has troubleshooting section
3. **Use AWS Console** - View error messages
4. **Check CloudWatch** - View logs
5. **Delete and Retry** - Sometimes faster than debugging

### Getting Help

```bash
# Check cluster status
aws eks describe-cluster --name training-cluster --region ap-southeast-1

# Check node status
kubectl get nodes

# View events
kubectl get events --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n kube-system -l k8s-app=aws-node
```

### Common Issues

**Cluster stuck in "Creating":**
- Check IAM role permissions
- Check VPC/subnet configuration
- View CloudFormation events

**Nodes not joining:**
- Check node role has required policies
- Check security group rules
- Check subnet has internet access

**Can't connect with kubectl:**
- Run: `aws eks update-kubeconfig --name training-cluster`
- Check AWS credentials
- Verify cluster is ACTIVE

---

## 💭 What You'll Learn About

### AWS Services
- VPC (Virtual Private Cloud)
- EC2 (Elastic Compute Cloud)
- EKS (Elastic Kubernetes Service)
- IAM (Identity and Access Management)
- CloudWatch (Monitoring)
- CloudFormation (Behind the scenes)

### Kubernetes Concepts
- Cluster architecture
- Pods and deployments
- Services (NodePort)
- kubectl commands
- Resource management

### Best Practices
- Multi-AZ deployment
- IAM role separation
- Security groups
- Cost optimization
- Resource tagging

---

## 🎯 Success Criteria

You've successfully completed Activity 3 when:

- [ ] EKS cluster is ACTIVE
- [ ] 2 worker nodes are Ready
- [ ] Todo app is deployed and accessible
- [ ] You understand each component
- [ ] **Everything is deleted and cleanup verified**

---

## 🚀 After Completion

### What's Next?

1. **Reflect on the process**
   - How long did it take?
   - What was confusing?
   - What would you automate?

2. **Activity 4: Scripted Setup**
   - See how eksctl automates this
   - Create same cluster in 20 minutes
   - Deploy microservices version

3. **Compare both approaches**
   - Manual: Learning value, full control
   - Scripted: Speed, reproducibility

---

## 📖 Additional Resources

- [EKS Workshop](https://www.eksworkshop.com/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- **Your cheatsheets:** Activity2 folder

---

## ⚠️ Final Reminders

### Before You Start

1. Set budget alert in AWS
2. Have 3-4 hours available
3. Choose a time when you can focus
4. Have coffee/tea ready ☕

### While Working

1. Read each guide completely before starting
2. Follow steps in order
3. Take screenshots of errors
4. Don't skip steps

### After Completion

1. **DELETE EVERYTHING** (Step 7)
2. Verify deletion in AWS Console
3. Check no CloudFormation stacks remain
4. Verify no charges accruing

---

**Ready to start?** Begin with [ARCHITECTURE.md](ARCHITECTURE.md) to understand what you're building!

**Remember:** This is the learning way. Activity 4 shows the production way! 🎓

