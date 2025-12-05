# Activity 4: Scripted Setup - The Production Way

Welcome to Activity 4! After manually creating a cluster in Activity 3, you'll now see how eksctl automates everything - and learn about microservices architecture.

---

## 🔑 IMPORTANT: Personalize Your Setup First!

**Each participant will create their OWN cluster with their OWN namespace.**

👉 **Read the detailed guide:** [00-PERSONALIZATION-GUIDE.md](00-PERSONALIZATION-GUIDE.md)

Before starting, you MUST replace `CHANGEME` with your IAM username in these files:
1. `cluster-config.yaml` - Your cluster name
2. `app-manifests/namespace.yaml` - Your namespace
3. `app-manifests/backend-deployment.yaml` - Namespace references
4. `app-manifests/frontend-deployment.yaml` - Namespace references

### Example Usernames:
- eks-thon → `eks-thon-cluster` and `thon-todo-app`
- eks-pythia → `eks-pythia-cluster` and `pythia-todo-app`
- eks-cronus → `eks-cronus-cluster` and `cronus-todo-app`
- eks-rhea → `eks-rhea-cluster` and `rhea-todo-app`
- eks-atlas → `eks-atlas-cluster` and `atlas-todo-app`
- eks-helios → `eks-helios-cluster` and `helios-todo-app`
- eks-selene → `eks-selene-cluster` and `selene-todo-app`

### Quick Personalization (Copy-Paste Method):

```bash
# 1. Find your IAM username
aws sts get-caller-identity --query Arn --output text
# Example output: arn:aws:iam::123456789012:user/eks-thon

# 2. Set your username as a variable (replace 'thon' with your username)
export MY_USERNAME="thon"

# 3. Navigate to Activity 4 directory
cd /path/to/EKS-Training/Activity4-Scripted-Setup

# 4. Replace CHANGEME in all files (macOS/Linux)
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/namespace.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/backend-deployment.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/frontend-deployment.yaml

# 5. Verify changes
grep -n "thon" cluster-config.yaml app-manifests/*.yaml
```

### Manual Personalization (If you prefer):

Open each file and use Find & Replace:
- Find: `CHANGEME`
- Replace: `thon` (or your username)

**⚠️ Don't skip this step!** Without personalization, all participants would create clusters with the same name, which will cause conflicts.

### Verify Your Personalization:

```bash
# Run the validation script
./validate-personalization.sh

# Expected output:
# ✅ PASS: All files validated
# 🎉 SUCCESS! You're ready to create your cluster!
```

---

## 🎯 Learning Objectives

By the end of this activity, you will:

- ✅ Understand Kubernetes workload types (Jobs, StatefulSets, etc.)
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
| 00a | Kubernetes Primitives Overview | 15 min |
| 00b | Understand Monolith vs Microservices | 20 min |
| 01 | Review cluster-config.yaml | 30 min |
| 02 | Create cluster with eksctl | 5 min + 20 min wait |
| 03 | Deploy microservices app | 30 min |
| 04 | Testing and verification | 15 min |
| 05 | Cleanup | 5 min + 10 min wait |

**Active time:** ~2 hours  
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
├── 00-PERSONALIZATION-GUIDE.md (START HERE - Personalize files!)
├── validate-personalization.sh (Run this to verify personalization!)
├── cluster-config.yaml (EKS configuration - MUST personalize)
├── 00-Kubernetes-Primitives-Overview.md
├── app-manifests/ (Application manifests - MUST personalize)
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
└── [Additional guides - optional]
```

**⚠️ Files marked "MUST personalize" need CHANGEME replaced with your username!**

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
# 0. FIRST: Find your IAM username
aws sts get-caller-identity --query Arn --output text
# Example: arn:aws:iam::123456789012:user/eks-thon
# Your username is: thon

# 1. Navigate to this directory
cd /path/to/Activity4-Scripted-Setup

# 2. PERSONALIZE: Replace CHANGEME with your username (REQUIRED!)
export MY_USERNAME="thon"  # Replace with YOUR username
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/*.yaml

# 3. Verify personalization worked
./validate-personalization.sh
# This script checks all files and confirms you're ready!

# OR manually verify:
grep "$MY_USERNAME" cluster-config.yaml
# Should see: name: eks-thon-cluster (or your username)

# 4. Review your personalized config (optional but recommended)
cat cluster-config.yaml

# 5. Create YOUR cluster (one command!)
eksctl create cluster -f cluster-config.yaml

# 6. Wait 20 minutes ☕
# Your cluster: eks-thon-cluster (or your username)

# 7. Deploy microservices app to YOUR namespace
kubectl apply -f app-manifests/

# 8. Verify deployment
kubectl get pods -n ${MY_USERNAME}-todo-app
kubectl get svc -n ${MY_USERNAME}-todo-app

# 9. Get access URL
kubectl get nodes -o wide
# Access at: http://node-ip:30080

# 10. When done, cleanup YOUR cluster
eksctl delete cluster --name eks-${MY_USERNAME}-cluster --region ap-southeast-1
```

**That's it!** But please read the detailed guides to understand what's happening.

---

## 📖 Step-by-Step Guides

### For Complete Understanding

1. **[00-Kubernetes-Primitives-Overview.md](00-Kubernetes-Primitives-Overview.md)** - NEW! Start here!
   - Understand Kubernetes workload types
   - Jobs, CronJobs, StatefulSets, DaemonSets
   - Secrets, ConfigMaps, Persistent Volumes
   - When to use each primitive
   - **Note:** Conceptual overview; hands-on labs in Activity 5

2. **[00-Monolith-vs-Microservices-Practice.md](00-Monolith-vs-Microservices-Practice.md)** - Architecture comparison
   - Compare Activity 3 (monolith) vs Activity 4 (microservices)
   - Understand when to use each approach
   - See pros and cons

3. **[01-Config-Explained.md](01-Config-Explained.md)** - Understand the YAML
   - Line-by-line explanation of `cluster-config.yaml`
   - Why each setting matters
   - Cost implications

4. **[02-Eksctl-Deployment.md](02-Eksctl-Deployment.md)** - Create the cluster
   - Run eksctl create cluster
   - Monitor progress
   - Verify cluster is ready

5. **[03-Deploy-Application.md](03-Deploy-Application.md)** - Deploy microservices
   - Apply Kubernetes manifests
   - Understand service-to-service communication
   - Configure kubectl

6. **[04-Verification.md](04-Verification.md)** - Test everything
   - Verify pods running
   - Test frontend access
   - Test backend API
   - Verify microservices communication

7. **[05-CLEANUP.md](05-CLEANUP.md)** - ⚠️ Delete everything
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
- Different Kubernetes workload types
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
- [ ] AWS CLI configured with YOUR IAM user credentials
- [ ] Know YOUR IAM username (e.g., eks-thon, eks-pythia)
- [ ] **Personalized all YAML files with YOUR username**
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

- [ ] Files personalized with YOUR username (CHANGEME replaced)
- [ ] YOUR cluster created with eksctl (e.g., eks-thon-cluster)
- [ ] 2 nodes Running in YOUR cluster
- [ ] Frontend and Backend deployed to YOUR namespace (e.g., thon-todo-app)
- [ ] Frontend can communicate with Backend
- [ ] Application accessible via browser
- [ ] You understand IaC benefits
- [ ] **YOUR cluster and resources deleted**

---

## 🔗 Quick Links

### Essential Files
- **Personalization Guide:** [00-PERSONALIZATION-GUIDE.md](00-PERSONALIZATION-GUIDE.md) - Detailed setup instructions
- **Validation Script:** [validate-personalization.sh](validate-personalization.sh) - Verify your setup
- **Quick Reference Card:** [QUICK-REFERENCE-CARD.md](QUICK-REFERENCE-CARD.md) - Print and use!

### For Instructors
- **Participant Resources:** [PARTICIPANT-RESOURCES.md](PARTICIPANT-RESOURCES.md) - Track all 7 participants

### Navigation
- **Previous:** [../Activity3-Console-Setup/README.md](../Activity3-Console-Setup/README.md)
- **Next:** [../Activity5-Advanced-Setup/README.md](../Activity5-Advanced-Setup/README.md)
- **Sample App:** [../sample-app/](../sample-app/)

---

## 🆘 Need Help?

### Common Issues

**Forgot to personalize files:**
```bash
# Error: Cluster "eks-CHANGEME-cluster" already exists
# Solution: Replace CHANGEME with your username
export MY_USERNAME="thon"  # Your username
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/*.yaml
```

**Wrong namespace in commands:**
```bash
# Error: namespace "todo-app" not found
# Solution: Use YOUR namespace
kubectl get pods -n thon-todo-app  # Replace 'thon' with YOUR username
```

**eksctl not found:**
```bash
# Install eksctl (see Activity 2)
brew install eksctl  # macOS
```

**AWS credentials error:**
```bash
# Configure AWS CLI with YOUR IAM user
aws configure
aws sts get-caller-identity
# Verify you see YOUR username in the ARN
```

**Cluster creation fails:**
```bash
# Check CloudFormation for YOUR cluster
aws cloudformation list-stacks --region ap-southeast-1 | grep eks-thon-cluster
```

### Getting Support

1. Check error messages
2. Review CloudWatch logs
3. Check eksctl GitHub issues
4. Review EKS documentation

---

**Ready to see automation magic?** Start with [00-Kubernetes-Primitives-Overview.md](00-Kubernetes-Primitives-Overview.md) to understand Kubernetes workload types, then proceed to [00-Monolith-vs-Microservices-Practice.md](00-Monolith-vs-Microservices-Practice.md)!

**Remember:** Activity 3 taught you the details. Activity 4 shows you the production way! 🚀

**Note:** Hands-on labs for Jobs, Secrets, StatefulSets, and Persistent Volumes are in Activity 5, Part A.

