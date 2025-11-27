# Activity 4: Scripted Setup - The Production Way

Welcome to Activity 4! After manually creating a cluster in Activity 3, you'll now see how eksctl automates everything - and learn about microservices architecture.

---

## 🎯 Learning Objectives

By the end of this activity, you will:

- ✅ Create EKS cluster using eksctl (one command!)
- ✅ Understand Infrastructure as Code (IaC)
- ✅ Deploy microservices Todo app (Frontend + Backend separately)
- ✅ Compare monolith vs microservices approaches
- ✅ See the benefits of automation
- ✅ Know the production deployment workflow

---

## ⏱️ Time Estimate

**Total Time: 2-2.5 hours**

| Step | Task | Time |
|------|------|------|
| 00 | Understand Monolith vs Microservices | 20 min |
| 01 | Review cluster-config.yaml | 30 min |
| 02 | Create cluster with eksctl | 5 min + 20 min wait |
| 03 | Deploy microservices app | 30 min |
| 04 | Testing and verification | 15 min |
| 05 | Cleanup | 5 min + 10 min wait |

**Active time:** ~1.75 hours  
**Wait time:** ~30 minutes  
**Cleanup:** ~15 minutes

---

## 💰 Cost Warning

**This activity costs money!**

```
Same as Activity 3:
├── EKS Control Plane: $0.10/hour ($2.40/day)
├── EC2 Nodes (2x t3.medium Spot): $0.025/hour ($0.60/day)
├── EBS Volumes (2x 20GB gp3): $0.11/day
└── Total: ~$3.15/day (~$0.13/hour)

Monthly if left running: ~$95
```

**⚠️ IMPORTANT:** Delete everything when done!

---

## 🆚 Activity 3 vs Activity 4

### What's Different?

| Aspect | Activity 3 (Manual) | Activity 4 (Scripted) |
|--------|-------------------|---------------------|
| **Method** | AWS Console clicks | eksctl YAML config |
| **Time** | ~3-4 hours | ~1.5-2 hours |
| **Steps** | 50+ manual steps | 1 command |
| **Reproducible** | No (click again) | Yes (same YAML) |
| **Error-prone** | Yes (easy to miss) | No (automated) |
| **App Type** | Monolith | Microservices |
| **Production** | No | Yes ✅ |

### Same Infrastructure

Both activities create:
- Same VPC setup
- Same security groups
- Same IAM roles
- Same EKS cluster
- Same 2 worker nodes

**Difference:** How it's created, not what is created!

---

## 📚 Files in This Activity

```
Activity4-Scripted-Setup/
├── README.md (this file)
├── ARCHITECTURE.md (architecture comparison)
├── cluster-config.yaml (EKS configuration)
├── 00-Monolith-vs-Microservices-Practice.md
├── 01-Config-Explained.md
├── 02-Eksctl-Deployment.md
├── 03-Deploy-Application.md
├── 04-Verification.md
├── 05-CLEANUP.md
├── cheatsheet.md
└── app-manifests/
    ├── namespace.yaml
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    └── frontend-service.yaml
```

---

## 🏗️ What You'll Build

```
Same infrastructure as Activity 3, BUT:
├── Created by: eksctl (not manual)
├── Time: 20 minutes (not 3 hours)
├── Reproducible: Yes (YAML file)
└── Application: Microservices (not monolith)

Microservices Architecture:
┌──────────────┐         ┌──────────────┐
│   Frontend   │────────▶│   Backend    │
│   Service    │  HTTP   │   Service    │
│              │ :3000   │              │
│   React      │         │   Node.js    │
│   nginx      │         │   Express    │
│              │         │              │
│   2 Pods     │         │   2 Pods     │
│   Port: 80   │         │   Port: 3000 │
└──────────────┘         └──────────────┘
      ▲                         ▲
      │                         │
   NodePort                 ClusterIP
   :30080                   (internal)
      │                         │
      └─────User Access─────────┘
```

---

## 🎯 Quick Start

If you've completed Activity 3 and understand the concepts:

```bash
# 1. Navigate to this directory
cd /path/to/Activity4-Scripted-Setup

# 2. Review config file (optional but recommended)
cat cluster-config.yaml

# 3. Create cluster (one command!)
eksctl create cluster -f cluster-config.yaml

# 4. Wait 20 minutes ☕

# 5. Deploy microservices app
kubectl apply -f app-manifests/

# 6. Get access URL
kubectl get nodes -o wide
# Access at: http://node-ip:30080

# 7. When done, cleanup
eksctl delete cluster --name training-cluster --region ap-southeast-1
```

**That's it!** But please read the detailed guides to understand what's happening.

---

## 📖 Step-by-Step Guides

### For Complete Understanding

1. **[00-Monolith-vs-Microservices-Practice.md](00-Monolith-vs-Microservices-Practice.md)** - Start here!
   - Compare Activity 3 (monolith) vs Activity 4 (microservices)
   - Understand when to use each approach
   - See pros and cons

2. **[01-Config-Explained.md](01-Config-Explained.md)** - Understand the YAML
   - Line-by-line explanation of `cluster-config.yaml`
   - Why each setting matters
   - Cost implications

3. **[02-Eksctl-Deployment.md](02-Eksctl-Deployment.md)** - Create the cluster
   - Run eksctl create cluster
   - Monitor progress
   - Verify cluster is ready

4. **[03-Deploy-Application.md](03-Deploy-Application.md)** - Deploy microservices
   - Apply Kubernetes manifests
   - Understand service-to-service communication
   - Configure kubectl

5. **[04-Verification.md](04-Verification.md)** - Test everything
   - Verify pods running
   - Test frontend access
   - Test backend API
   - Verify microservices communication

6. **[05-CLEANUP.md](05-CLEANUP.md)** - ⚠️ Delete everything
   - One command cleanup
   - Verify deletion
   - Check no charges

---

## 💡 Key Concepts

### Infrastructure as Code (IaC)

```
Traditional (Activity 3):
- Click through AWS Console
- Different person = different result
- Hard to document
- Can't version control
- Can't automate

IaC (Activity 4):
- Define in YAML file
- Same file = same result
- Self-documenting
- Version control in Git
- Fully automated
```

### Microservices Benefits

```
Monolith (Activity 3):
└── One container
    ├── Frontend + Backend together
    ├── Deploy all at once
    ├── Scale all together
    └── One failure = all down

Microservices (Activity 4):
├── Frontend container
│   ├── Independent deployment
│   ├── Independent scaling
│   └── Independent failure
└── Backend container
    ├── Independent deployment
    ├── Independent scaling
    └── Independent failure
```

---

## 🔍 What eksctl Does

When you run `eksctl create cluster -f cluster-config.yaml`:

```
eksctl automatically:
1. Creates VPC with subnets ✅
2. Creates Internet Gateway ✅
3. Configures route tables ✅
4. Creates security groups ✅
5. Creates IAM roles ✅
6. Attaches IAM policies ✅
7. Creates EKS cluster ✅
8. Creates node group ✅
9. Waits for everything to be ready ✅
10. Configures kubectl ✅

All the work from Activity 3 in ONE command!
```

---

## 🎓 Learning Outcomes

### After Activity 3 (Manual)
You know:
- What components are needed
- How they connect
- What can go wrong
- How to troubleshoot

### After Activity 4 (Scripted)
You know:
- How to automate everything
- How to use IaC
- How microservices work
- How services communicate
- Production deployment workflow

### Combined Knowledge
You can:
- Create clusters quickly
- Troubleshoot deep issues
- Deploy microservices
- Work professionally
- Interview confidently

---

## 🚀 Production Workflow

This is how real teams work:

```
1. Write cluster-config.yaml
   ├── Define infrastructure
   └── Commit to Git

2. Run eksctl create
   ├── Automated creation
   └── Consistent results

3. Deploy applications
   ├── kubectl apply -f manifests/
   └── Declarative deployment

4. Make changes
   ├── Update YAML files
   └── Apply changes

5. Destroy when needed
   ├── eksctl delete cluster
   └── Clean removal
```

---

## ⚠️ Important Notes

### Before Starting

- [ ] Completed Activity 3 (or understand concepts)
- [ ] All tools installed (Activity 2)
- [ ] AWS CLI configured
- [ ] Budget alert set

### During Activity

- **Don't skip reading the guides** - Understand what's happening
- **Review the YAML files** - This is how you'll work in production
- **Compare with Activity 3** - Appreciate the automation

### After Completion

- **Delete the cluster** - Follow cleanup guide
- **Review what you learned** - Compare both approaches
- **Move to Activity 5** - Learn advanced features

---

## 📊 File Explanations

### `cluster-config.yaml`

Defines the entire cluster:
- Cluster name and version
- VPC configuration
- Node group settings
- Spot instances
- Storage configuration
- All in one file!

### `app-manifests/*.yaml`

Defines the application:
- Namespace for organization
- Backend deployment and service
- Frontend deployment and service
- Service-to-service networking

---

## 💭 Reflection Questions

After completing this activity, ask yourself:

1. **Time:** How much faster was this than Activity 3?
2. **Reliability:** Would you get same result every time?
3. **Documentation:** Is the YAML file self-documenting?
4. **Microservices:** What are the benefits of separate services?
5. **Production:** Would you use Console or eksctl in production?

---

## ✅ Success Criteria

You've completed Activity 4 when:

- [ ] Cluster created with eksctl
- [ ] 2 nodes Running
- [ ] Frontend and Backend deployed separately
- [ ] Frontend can communicate with Backend
- [ ] Application accessible via browser
- [ ] You understand IaC benefits
- [ ] **Everything deleted**

---

## 🔗 Quick Links

- **Previous:** [../Activity3-Console-Setup/README.md](../Activity3-Console-Setup/README.md)
- **Next:** [../Activity5-Advanced-Setup/README.md](../Activity5-Advanced-Setup/README.md)
- **Cheatsheet:** [cheatsheet.md](cheatsheet.md)
- **Sample App:** [../sample-app/](../sample-app/)

---

## 🆘 Need Help?

### Common Issues

**eksctl not found:**
```bash
# Install eksctl (see Activity 2)
brew install eksctl  # macOS
```

**AWS credentials error:**
```bash
# Configure AWS CLI
aws configure
aws sts get-caller-identity
```

**Cluster creation fails:**
```bash
# Check CloudFormation
aws cloudformation list-stacks --region ap-southeast-1
```

### Getting Support

1. Check error messages
2. Review CloudWatch logs
3. Check eksctl GitHub issues
4. Review EKS documentation

---

**Ready to see automation magic?** Start with [00-Monolith-vs-Microservices-Practice.md](00-Monolith-vs-Microservices-Practice.md)!

**Remember:** Activity 3 taught you the details. Activity 4 shows you the production way! 🚀

