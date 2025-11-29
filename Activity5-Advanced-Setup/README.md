# Activity 5: Advanced Setup - Production-Ready Kubernetes

Welcome to Activity 5! This comprehensive activity covers production-grade Kubernetes: workloads, networking, auto-scaling, and CI/CD.

---

## 🎯 Learning Objectives

By the end of this activity, you will:

**Part A: Kubernetes Workloads**
- ✅ Work with Jobs and CronJobs
- ✅ Manage Secrets and ConfigMaps
- ✅ Deploy StatefulSets with persistent storage
- ✅ Understand Persistent Volumes (PV/PVC)

**Part B: Networking & Auto-Scaling**
- ✅ Implement Horizontal Pod Autoscaler (HPA)
- ✅ Configure Cluster Autoscaler
- ✅ Deploy AWS Load Balancer Controller
- ✅ Set up Application Load Balancer (ALB)

**Part C: CI/CD Pipeline**
- ✅ Deploy Jenkins on Kubernetes
- ✅ Configure ECR integration
- ✅ Build automated pipelines
- ✅ Implement GitOps workflows

---

## ⏱️ Time Estimate

**Total Time: 8-10 hours** (can be split over 2 days)

| Part | Topic | Time |
|------|-------|------|
| **A** | Kubernetes Workloads | 2-2.5 hours |
| **B** | Networking & Auto-Scaling | 3-3.5 hours |
| **C** | CI/CD Pipeline | 3-4 hours |

**Recommended Schedule:**
- Day 1: Parts A & B (5-6 hours)
- Day 2: Part C (3-4 hours)

---

## 💰 Cost Warning

**This activity costs more than Activities 3-4!**

```
Estimated costs while running:
├── EKS Control Plane: $0.10/hour ($2.40/day)
├── EC2 Nodes: $0.025-0.05/hour ($0.60-1.20/day)
├── ALB: $0.0225/hour ($0.54/day)
├── Jenkins: $0.03/hour ($0.72/day) - if on separate instance
├── Storage (PVCs): $0.15/day
└── Total: ~$5-7/day (~$0.20-0.30/hour)

Monthly if left running: ~$150-210
```

**⚠️ CRITICAL:** Delete all resources when done!

---

## 📚 Activity Structure

```
Activity5-Advanced-Setup/
├── README.md (this file)
├── ARCHITECTURE.md (overall architecture)
├── cluster-config-advanced.yaml
│
├── 08-Kubernetes-Workloads/  ← PART A
│   ├── 08-01-Jobs-And-CronJobs.md
│   ├── 08-02-Secrets-And-ConfigMaps.md
│   ├── 08-03-StatefulSets.md
│   └── 08-04-PersistentVolumes.md
│
├── 01-Metrics-Server.md  ← PART B
├── 02-HPA-Setup.md
├── 03-Cluster-Autoscaler.md
├── 04-ALB-Controller.md
├── 05-Ingress-SSL.md
├── 06-Load-Testing.md
│
├── 09-CI-CD-Pipeline/  ← PART C
│   ├── 09-01-Jenkins-Setup.md
│   ├── 09-02-ECR-Integration.md
│   ├── 09-03-Pipeline-Configuration.md
│   └── 09-04-Automated-Deployment.md
│
├── app-manifests/
│   ├── workloads/
│   │   ├── mysql-statefulset.yaml
│   │   ├── backup-cronjob.yaml
│   │   ├── app-secrets.yaml
│   │   └── app-configmap.yaml
│   ├── backend-hpa.yaml
│   ├── frontend-hpa.yaml
│   └── ingress.yaml
│
└── jenkins/
    ├── Jenkinsfile
    ├── jenkins-deployment.yaml
    ├── jenkins-pvc.yaml
    └── jenkins-service.yaml
```

---

## 🏗️ What You'll Build

### Part A: Kubernetes Workloads

```
Workloads:
├── Jobs: One-time batch tasks
├── CronJobs: Scheduled tasks (backups)
├── Secrets: Secure credential storage
├── ConfigMaps: Application configuration
├── StatefulSets: MySQL with persistent storage
└── Persistent Volumes: EBS-backed storage
```

### Part B: Networking & Auto-Scaling

```
┌─────────────────────────────────────────────┐
│      Application Load Balancer (ALB)        │
│      https://your-domain.com                │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐        ┌──────────────┐
│  Frontend    │        │  Backend     │
│  HPA: 2-10   │        │  HPA: 2-10   │
│  Auto-scales │        │  Auto-scales │
└──────────────┘        └──────────────┘

Cluster Autoscaler:
- Min: 2 nodes, Max: 5 nodes
- Scales based on pod resource requests
```

### Part C: CI/CD Pipeline

```
Git Push → Webhook → Jenkins → Build → Test
   ↓
Docker Build → ECR Push → K8s Deploy → Verify

Components:
├── Jenkins on Kubernetes
├── Dynamic build agents
├── ECR for Docker images
├── Automated deployments
└── GitOps workflow
```

---

## 🎯 Quick Start

### Prerequisites

- Completed Activity 4 (or understand eksctl)
- Tools installed (Activity 2)
- AWS CLI configured
- Budget alert set

### Create Cluster

```bash
# 1. Create cluster with advanced configuration
cd Activity5-Advanced-Setup
eksctl create cluster -f cluster-config-advanced.yaml

# Wait 20 minutes for cluster creation

# 2. Verify cluster
kubectl get nodes
kubectl get pods -A
```

---

## 📖 Learning Path

### **Part A: Kubernetes Workloads** (Start Here!)

**Hands-on with core Kubernetes primitives:**

1. **[08-01-Jobs-And-CronJobs.md](08-Kubernetes-Workloads/08-01-Jobs-And-CronJobs.md)**
   - Create and manage Jobs
   - Schedule tasks with CronJobs
   - Database backup examples
   - ⏱️ 30-40 min

2. **[08-02-Secrets-And-ConfigMaps.md](08-Kubernetes-Workloads/08-02-Secrets-And-ConfigMaps.md)**
   - Store application configuration
   - Manage sensitive data securely
   - Mount config as files or env vars
   - ⏱️ 30-35 min

3. **[08-03-StatefulSets.md](08-Kubernetes-Workloads/08-03-StatefulSets.md)**
   - Deploy MySQL with persistent storage
   - Understand stable network identities
   - Scale stateful applications
   - ⏱️ 40-45 min

4. **[08-04-PersistentVolumes.md](08-Kubernetes-Workloads/08-04-PersistentVolumes.md)**
   - Deep dive into Kubernetes storage
   - Work with StorageClasses and PVCs
   - Create volume snapshots
   - ⏱️ 35-40 min

**Total Part A: ~2-2.5 hours**

---

### **Part B: Networking & Auto-Scaling**

**Production-ready networking and scaling:**

1. **[01-Metrics-Server.md](01-Metrics-Server.md)**
   - Install metrics server
   - Monitor resource usage
   - ⏱️ 20 min

2. **[02-HPA-Setup.md](02-HPA-Setup.md)**
   - Configure Horizontal Pod Autoscaler
   - Auto-scale based on CPU/memory
   - ⏱️ 30 min

3. **[03-Cluster-Autoscaler.md](03-Cluster-Autoscaler.md)**
   - Auto-scale cluster nodes
   - Configure min/max nodes
   - ⏱️ 40 min

4. **[04-ALB-Controller.md](04-ALB-Controller.md)**
   - Deploy AWS Load Balancer Controller
   - Configure IAM permissions
   - ⏱️ 40 min

5. **[05-Ingress-SSL.md](05-Ingress-SSL.md)**
   - Create Ingress resources
   - Configure SSL with ACM
   - ⏱️ 40 min

6. **[06-Load-Testing.md](06-Load-Testing.md)**
   - Test auto-scaling under load
   - Monitor scaling behavior
   - ⏱️ 30 min

**Total Part B: ~3-3.5 hours**

---

### **Part C: CI/CD Pipeline**

**Complete automated deployment pipeline:**

1. **[09-01-Jenkins-Setup.md](09-CI-CD-Pipeline/09-01-Jenkins-Setup.md)**
   - Deploy Jenkins on Kubernetes
   - Configure persistent storage
   - Set up plugins and credentials
   - ⏱️ 45-60 min

2. **[09-02-ECR-Integration.md](09-CI-CD-Pipeline/09-02-ECR-Integration.md)**
   - Create ECR repository
   - Configure Jenkins with AWS
   - Push Docker images to ECR
   - ⏱️ 30-35 min

3. **[09-03-Pipeline-Configuration.md](09-CI-CD-Pipeline/09-03-Pipeline-Configuration.md)**
   - Create production-ready Jenkinsfile
   - Configure Git webhooks
   - Add testing and notifications
   - ⏱️ 40-45 min

4. **[09-04-Automated-Deployment.md](09-CI-CD-Pipeline/09-04-Automated-Deployment.md)**
   - Implement GitOps workflow
   - Configure deployment strategies
   - Set up monitoring and rollback
   - ⏱️ 35-40 min

**Total Part C: ~3-4 hours**

---

## 🎓 What You'll Learn

### Technical Skills

**Kubernetes:**
- Jobs, CronJobs, StatefulSets, DaemonSets
- Secrets, ConfigMaps, Persistent Volumes
- Horizontal and vertical scaling
- Network policies and Ingress
- Storage management

**AWS:**
- EKS advanced features
- ECR (Elastic Container Registry)
- ALB (Application Load Balancer)
- ACM (Certificate Manager)
- IAM for Kubernetes

**CI/CD:**
- Jenkins on Kubernetes
- Docker image building
- Automated testing
- GitOps workflows
- Deployment strategies (blue-green, canary)

### Production Patterns

```
✅ Auto-scaling (pods and nodes)
✅ Load balancing (Layer 7)
✅ SSL/TLS termination
✅ Persistent storage
✅ Configuration management
✅ Secrets management
✅ Automated deployments
✅ Rollback strategies
✅ Monitoring and logging
```

---

## ⚠️ Important Notes

### Before Starting

- [ ] Budget alert configured
- [ ] Time allocated (8-10 hours)
- [ ] Tools installed (Activity 2)
- [ ] Cluster ready or will create new one

### During Activity

- **Follow parts in order:** A → B → C
- **Don't skip hands-on labs**
- **Test everything as you go**
- **Take notes on new concepts**

### After Each Part

- **Review what you learned**
- **Can delete resources between parts** (to save costs)
- **But easier to keep cluster running** for all 3 parts

### After Completion

- **Delete cluster:** `eksctl delete cluster`
- **Delete Load Balancers:** Check AWS Console
- **Delete ECR repository:** If no longer needed
- **Verify all resources deleted**

---

## ✅ Success Criteria

You've completed Activity 5 when:

**Part A:**
- [ ] Ran Jobs and CronJobs successfully
- [ ] Used Secrets and ConfigMaps
- [ ] Deployed MySQL with StatefulSet
- [ ] Worked with Persistent Volumes

**Part B:**
- [ ] Metrics-server running
- [ ] HPA scaling pods automatically
- [ ] Cluster Autoscaler adding/removing nodes
- [ ] ALB routing traffic with SSL

**Part C:**
- [ ] Jenkins deployed and accessible
- [ ] Pipeline building and pushing to ECR
- [ ] Automated deployments working
- [ ] Git webhooks triggering builds

**Overall:**
- [ ] Understand all production patterns
- [ ] Can troubleshoot issues
- [ ] **Everything deleted to stop charges**

---

## 💰 Cost Management

### Minimizing Costs

```bash
# Option 1: Complete all parts in one session (8-10 hours)
# Keep cluster running throughout
# Delete everything at end

# Option 2: Split across days
# Day 1: Parts A & B
# Delete cluster at end of day
# Day 2: Recreate cluster, do Part C
# Delete everything at end

# Option 3: Practice parts individually
# Create cluster
# Do one part
# Delete cluster
# Repeat for other parts
```

### Monitoring Costs

```bash
# Check running resources
kubectl get all -A
kubectl get pvc -A

# Check AWS resources
aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=*"
aws elbv2 describe-load-balancers
aws ecr describe-repositories
```

---

## 🆘 Need Help?

### Common Issues

**Part A:**
- Jobs stuck: Check pod logs and events
- PVC not binding: Verify StorageClass exists
- StatefulSet not starting: Check volume availability

**Part B:**
- HPA not scaling: Verify metrics-server running
- ALB not creating: Check IAM permissions
- Ingress not working: Verify ALB Controller logs

**Part C:**
- Jenkins not starting: Check PVC status
- Pipeline failing: Verify AWS credentials
- Images not pushing: Check ECR permissions

### Getting Support

1. Check guide-specific troubleshooting sections
2. Review pod logs: `kubectl logs`
3. Check events: `kubectl get events`
4. Review AWS CloudWatch logs
5. Check EKS documentation

---

## 🔗 Quick Links

- **Previous:** [../Activity4-Scripted-Setup/README.md](../Activity4-Scripted-Setup/README.md)
- **Main README:** [../README.md](../README.md)
- **Sample App:** [../sample-app/](../sample-app/)

---

## 🎉 Ready to Begin?

**Start with Part A:** [08-Kubernetes-Workloads/08-01-Jobs-And-CronJobs.md](08-Kubernetes-Workloads/08-01-Jobs-And-CronJobs.md)

**Remember:**
- Take your time
- Hands-on practice is key
- Test everything
- Delete resources when done
- Have fun learning! 🚀

---

**From basic Kubernetes to production-ready deployments - let's do this!** 💪

