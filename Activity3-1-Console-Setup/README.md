# Activity 3-1: Shared EKS Cluster Setup (Console-Based)

Welcome to Activity 3-1! This is a **shared environment** where all 7 participants will work on the **same EKS cluster**. This approach is different from Activity 3 where each person creates their own cluster.

---

## 🎯 Learning Objectives

By the end of this activity, you will:

- ✅ Understand how a shared EKS cluster is set up and managed
- ✅ Learn to work collaboratively in a shared Kubernetes environment
- ✅ Deploy and manage your own applications in personal namespaces
- ✅ Create and manage worker nodes and node groups
- ✅ Build, push, and pull Docker images from Amazon ECR
- ✅ Understand AWS permissions (IAM) and Kubernetes permissions (RBAC)
- ✅ Practice safe operations in a multi-user environment

---

## 🆚 Activity 3 vs Activity 3-1

### Activity 3: Individual Setup
```
Each participant:
├── Creates their own VPC
├── Creates their own EKS cluster
├── Manages their own resources
├── Full isolation
└── Cost: 7 clusters × $95 = $665/month
```

### Activity 3-1: Shared Setup (This Activity)
```
All participants:
├── Share ONE VPC
├── Share ONE EKS cluster
├── Work in personal namespaces
├── Coordinate on shared resources
└── Cost: 1 cluster = $95/month (saves $570!)
```

**Key Difference:** In this activity, you'll learn **collaboration** and **coordination** skills essential for real-world team environments!

---

## 👥 Who Does What?

### Root Account (Workshop Admin)
**Creates the foundation** - ~2 hours of setup:
- ✅ VPC and networking infrastructure
- ✅ EKS cluster (with initial node group)
- ✅ Shared ECR repository
- ✅ Grants access to all participants

### Participants (You!)
**Use the foundation** to learn and practice:
- ✅ Connect to the shared cluster
- ✅ Create personal namespaces
- ✅ Create and manage node groups
- ✅ Build, tag, and push Docker images to ECR
- ✅ Deploy applications
- ✅ Test and validate deployments

---

## ⏱️ Time Estimates

### For Root Account (One-time Setup)
| Step | Task | Time |
|------|------|------|
| 01 | VPC & Networking | 30 min |
| 02 | IAM Roles | 20 min |
| 03 | EKS Cluster | 30 min + 20 min wait |
| 04 | ECR Repository | 10 min |
| 05 | Grant Access | 15 min |
| **Total** | **Setup Complete** | **~2 hours** |

### For Participants (Your Learning Time)
| Step | Task | Time |
|------|------|------|
| 01 | Connect to Cluster | 10 min |
| 02 | Namespace Management | 15 min |
| 03 | Node Group Management | 30 min |
| 04 | ECR Image Workflow | 30 min |
| 05 | Deploy Applications | 40 min |
| 06 | Testing & Validation | 30 min |
| **Total** | **Learning Complete** | **~2.5-3 hours** |

---

## 💰 Cost Breakdown

### This Shared Setup
```
Fixed Costs (ONE cluster for everyone):
├── EKS Control Plane: $72/month ($2.40/day)
├── Worker Nodes (2× t3.medium Spot): $18/month ($0.60/day)
├── EBS Volumes (2× 20GB gp3): $3.20/month ($0.11/day)
├── CloudWatch Logs: ~$1-2/month
├── Data Transfer: ~$0.50/month
└── ECR Storage: $0.10/GB/month

Total: ~$95/month (~$3.15/day)

If workshop runs 4 hours:
└── Cost: $0.13/hour × 4 = $0.52 total for ALL 7 participants!
```

### Alternative: Individual Setup (Activity 3)
```
7 separate clusters:
└── 7 × $95 = $665/month
    4 hours: 7 × $0.52 = $3.64 total

Savings with shared setup: $3.12 (85% cheaper!)
```

---

## 🚨 Important Safety Warnings

### ⚠️ FULL ADMIN ACCESS

All participants have **full administrative access** to the shared cluster. This means:

**You CAN:**
- ✅ Create/delete namespaces
- ✅ Deploy applications anywhere
- ✅ Create/delete node groups
- ✅ Modify cluster resources
- ✅ View all workloads

**You MUST NOT:**
- ❌ Delete the entire cluster
- ❌ Delete other participants' namespaces
- ❌ Delete all node groups (always leave at least one!)
- ❌ Modify system namespaces (kube-system, kube-public, etc.)
- ❌ Use all cluster resources

**Golden Rule:** _If you're not sure, ASK before doing it!_

**Read this BEFORE starting:** [SAFETY-GUIDELINES.md](SAFETY-GUIDELINES.md)

---

## 📚 Documentation Structure

### For Root Account (Setup)

Start here if you're the workshop administrator:

1. **[ROOT-SETUP/01-VPC-AND-NETWORKING.md](ROOT-SETUP/01-VPC-AND-NETWORKING.md)**
   - Create VPC with 10.0.0.0/16 CIDR
   - Create 2 public subnets across availability zones
   - Set up Internet Gateway and route tables
   - Configure security groups

2. **[ROOT-SETUP/02-IAM-ROLES.md](ROOT-SETUP/02-IAM-ROLES.md)**
   - Create EKS cluster service role
   - Create EKS node instance role
   - Attach required AWS managed policies

3. **[ROOT-SETUP/03-EKS-CLUSTER-CREATION.md](ROOT-SETUP/03-EKS-CLUSTER-CREATION.md)**
   - Create EKS cluster named `shared-workshop-cluster`
   - Configure networking and security
   - Wait for cluster to become Active

4. **[ROOT-SETUP/04-ECR-REGISTRY-SETUP.md](ROOT-SETUP/04-ECR-REGISTRY-SETUP.md)**
   - Create shared ECR repository `eks-workshop-apps`
   - Configure repository permissions
   - Set up lifecycle policies

5. **[ROOT-SETUP/05-PARTICIPANT-ACCESS.md](ROOT-SETUP/05-PARTICIPANT-ACCESS.md)**
   - Configure aws-auth ConfigMap
   - Grant cluster admin access to participants
   - Test access with one participant account

**Quick Reference:** [ROOT-SETUP/SETUP-CHEATSHEET.md](ROOT-SETUP/SETUP-CHEATSHEET.md)

---

### For Participants (Learning & Practice)

Start here if you're a workshop participant:

1. **[00-SETUP-PREREQUISITES.md](00-SETUP-PREREQUISITES.md)** - Read this first!
   - Required tools (AWS CLI, kubectl, Docker)
   - AWS credentials setup
   - Verify your access

2. **[PARTICIPANT-GUIDES/01-CONNECT-TO-CLUSTER.md](PARTICIPANT-GUIDES/01-CONNECT-TO-CLUSTER.md)**
   - Configure kubectl to access the shared cluster
   - Verify connection and permissions
   - Understand the cluster layout

3. **[PARTICIPANT-GUIDES/02-NAMESPACE-MANAGEMENT.md](PARTICIPANT-GUIDES/02-NAMESPACE-MANAGEMENT.md)**
   - Create your personal namespace
   - Set as default namespace
   - Understand namespace isolation

4. **[PARTICIPANT-GUIDES/03-NODE-GROUP-MANAGEMENT.md](PARTICIPANT-GUIDES/03-NODE-GROUP-MANAGEMENT.md)**
   - View and understand nodes
   - Create additional node groups (carefully!)
   - Scale node groups and manage nodes

5. **[PARTICIPANT-GUIDES/04-ECR-IMAGE-WORKFLOW.md](PARTICIPANT-GUIDES/04-ECR-IMAGE-WORKFLOW.md)**
   - Build Docker images
   - Tag and push to shared ECR
   - Pull images for deployments

6. **[PARTICIPANT-GUIDES/05-DEPLOY-APPLICATIONS.md](PARTICIPANT-GUIDES/05-DEPLOY-APPLICATIONS.md)**
   - Create deployments and pods
   - Expose applications with services
   - Scale and manage workloads

7. **[PARTICIPANT-GUIDES/06-TESTING-AND-VALIDATION.md](PARTICIPANT-GUIDES/06-TESTING-AND-VALIDATION.md)**
   - Test your deployments
   - Verify high availability
   - Monitor resource usage

**Quick Reference:** [PARTICIPANT-GUIDES/PARTICIPANT-CHEATSHEET.md](PARTICIPANT-GUIDES/PARTICIPANT-CHEATSHEET.md)

---

### Reference Materials (Everyone)

- **[REFERENCE/AWS-CLI-COMMANDS.md](REFERENCE/AWS-CLI-COMMANDS.md)**
  - Complete AWS CLI command reference
  - EKS, EC2, ECR, IAM commands with examples

- **[REFERENCE/KUBECTL-COMMANDS.md](REFERENCE/KUBECTL-COMMANDS.md)**
  - Complete kubectl command reference
  - Organized by resource type with examples

- **[REFERENCE/PERMISSIONS-REFERENCE.md](REFERENCE/PERMISSIONS-REFERENCE.md)**
  - IAM vs RBAC explained
  - Understanding your permissions
  - Security best practices

- **[REFERENCE/TROUBLESHOOTING.md](REFERENCE/TROUBLESHOOTING.md)**
  - Common issues and solutions
  - Error messages decoded
  - How to get help

---

### Safety & Cleanup

- **[SAFETY-GUIDELINES.md](SAFETY-GUIDELINES.md)** ⚠️ **READ THIS!**
  - Best practices for shared environment
  - Naming conventions
  - What NOT to do
  - Communication protocols

- **[ARCHITECTURE.md](ARCHITECTURE.md)**
  - Complete architecture diagram
  - How everything connects
  - Cost breakdown details

- **[CLEANUP-GUIDE.md](CLEANUP-GUIDE.md)** (Root only)
  - Delete all resources at end of workshop
  - Verify no ongoing charges

---

## 🏗️ What You'll Build

```
┌─────────────────────────────────────────────────────────────────┐
│              AWS Account (ap-southeast-1)                       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           Shared VPC: 10.0.0.0/16                        │  │
│  │                                                          │  │
│  │   ┌──────────────┐           ┌──────────────┐          │  │
│  │   │ Public       │           │ Public       │          │  │
│  │   │ Subnet A     │           │ Subnet B     │          │  │
│  │   │ AZ-1a        │           │ AZ-1b        │          │  │
│  │   │              │           │              │          │  │
│  │   │ [Node 1]     │           │ [Node 2]     │          │  │
│  │   │ t3.medium    │           │ t3.medium    │          │  │
│  │   └──────────────┘           └──────────────┘          │  │
│  │                                                          │  │
│  │   [Internet Gateway] ←→ Internet                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │    EKS Cluster: shared-workshop-cluster                  │  │
│  │    Control Plane (AWS Managed - Multi-AZ)                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │    Participant Namespaces:                               │  │
│  │    ├── charles-workspace   (Charles's apps)              │  │
│  │    ├── joshua-workspace    (Joshua's apps)               │  │
│  │    ├── robert-workspace    (Robert's apps)               │  │
│  │    ├── sharmaine-workspace (Sharmaine's apps)            │  │
│  │    ├── daniel-workspace    (Daniel's apps)               │  │
│  │    ├── jett-workspace      (Jett's apps)                 │  │
│  │    └── thon-workspace      (Thon's apps)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │    ECR Repository: eks-workshop-apps                     │  │
│  │    Images:                                               │  │
│  │    ├── charles-webapp-v1                                 │  │
│  │    ├── joshua-api-v1                                     │  │
│  │    ├── robert-frontend-v2                                │  │
│  │    └── ... (all participant images)                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

All 7 participants → Same Cluster → Personal Namespaces
```

---

## 💡 Why Shared Setup?

### Learning Benefits

**Collaboration Skills:**
- Work with others on shared infrastructure
- Coordinate resource usage
- Practice communication
- Real-world team environment

**Cost Efficiency:**
- 85% cheaper than individual clusters
- Learn same concepts with less cost
- Practical for workshops and training

**Real-World Simulation:**
- Most companies use shared clusters
- Multiple teams share infrastructure
- Learn namespace isolation
- Understand multi-tenancy

### When to Use This vs Individual Setup

**Use Shared Setup (Activity 3-1) When:**
- ✅ Running workshops with multiple people
- ✅ Budget is limited
- ✅ Want to teach collaboration
- ✅ Short-term learning (hours/days)

**Use Individual Setup (Activity 3) When:**
- ✅ Learning alone
- ✅ Need full isolation
- ✅ Long-term practice
- ✅ Want complete control

---

## 🚀 Getting Started

### If You're Root (Admin):
1. Read [ROOT-SETUP/01-VPC-AND-NETWORKING.md](ROOT-SETUP/01-VPC-AND-NETWORKING.md)
2. Follow ROOT-SETUP guides in order (01 → 06)
3. Allow 2 hours for complete setup
4. Share cluster access with participants

### If You're a Participant:
1. **READ FIRST:** [SAFETY-GUIDELINES.md](SAFETY-GUIDELINES.md) ⚠️
2. Check [00-SETUP-PREREQUISITES.md](00-SETUP-PREREQUISITES.md)
3. Get credentials from workshop admin
4. Follow PARTICIPANT-GUIDES in order (01 → 06)
5. Communicate with other participants!

---

## ✅ Success Criteria

### For Root:
- [ ] VPC and networking created
- [ ] EKS cluster Active
- [ ] 2 nodes Ready
- [ ] ECR repository created
- [ ] All 7 participants can connect
- [ ] aws-auth ConfigMap configured

### For Participants:
- [ ] Can connect to cluster with kubectl
- [ ] Created personal namespace
- [ ] Deployed at least one application
- [ ] Pushed image to ECR
- [ ] Successfully accessed application
- [ ] Understood shared environment practices

---

## 🆘 Getting Help

### Common Issues?
Check [REFERENCE/TROUBLESHOOTING.md](REFERENCE/TROUBLESHOOTING.md)

### Need Command Reference?
- AWS CLI: [REFERENCE/AWS-CLI-COMMANDS.md](REFERENCE/AWS-CLI-COMMANDS.md)
- kubectl: [REFERENCE/KUBECTL-COMMANDS.md](REFERENCE/KUBECTL-COMMANDS.md)

### Permission Issues?
Read [REFERENCE/PERMISSIONS-REFERENCE.md](REFERENCE/PERMISSIONS-REFERENCE.md)

### Coordinator Communication:
- Ask workshop admin
- Coordinate with other participants
- Use team chat/Slack
- Report issues immediately

---

## 📖 Additional Resources

- [EKS Workshop](https://www.eksworkshop.com/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- Activity 2 Tool Cheatsheets (../Activity2-Tools-And-Commands/)

---

## ⚠️ Final Reminders

### Before You Start:
1. **Root:** Have 2 uninterrupted hours for setup
2. **Participants:** Get credentials from admin first
3. **Everyone:** Read SAFETY-GUIDELINES.md
4. **Everyone:** Understand this is a SHARED environment

### While Working:
1. **Communicate** before major actions
2. **Use personal namespaces** for your work
3. **Follow naming conventions** (username-appname)
4. **Monitor resources** - don't use everything
5. **Ask if unsure** - better safe than sorry!

### After Completion:
1. **Root:** Follow CLEANUP-GUIDE.md
2. **Participants:** Delete your namespaces (optional)
3. **Everyone:** Verify no ongoing charges
4. **Everyone:** Reflect on what you learned!

---

**Ready to start?**

- **Root/Admin:** Begin with [ROOT-SETUP/01-VPC-AND-NETWORKING.md](ROOT-SETUP/01-VPC-AND-NETWORKING.md)
- **Participants:** Start with [00-SETUP-PREREQUISITES.md](00-SETUP-PREREQUISITES.md)

**Remember:** Communication and coordination are key in a shared environment! 🤝

