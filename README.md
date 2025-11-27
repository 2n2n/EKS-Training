# EKS Training Program - Complete Guide

**From Traditional Hosting to Cloud-Native Kubernetes**

Welcome to the comprehensive EKS (Amazon Elastic Kubernetes Service) training program! This training is specifically designed for developers and sysadmins transitioning from traditional hosting environments (VPS, dedicated servers, monolith architectures) to modern cloud-native Kubernetes deployments.

---

## 🎯 Who This Training Is For

### Target Audience

- **Traditional Hosting Users**: Familiar with VPS, dedicated servers, cPanel/Plesk
- **Monolith Developers**: Deploy applications as single units to servers
- **System Administrators**: Manage servers manually with SSH
- **DevOps Beginners**: Looking to modernize infrastructure
- **AWS Newcomers**: Little to no cloud experience but eager to learn

### What You Should Know

- Basic Linux/server administration
- How to SSH into a server
- Basic networking concepts (IP addresses, ports)
- How to deploy applications (even if manually)
- Understanding of servers, databases, and web applications

---

## 📚 Program Overview

### Learning Journey

```
Activity 1: Prerequisites (3-4 hours)
├── Why Kubernetes exists
├── Traditional vs Cloud comparison
├── Docker and containers
├── Kubernetes concepts
├── AWS fundamentals
├── Networking basics
└── IAM and security
    │
    ▼
Activity 2: Tools Setup (30-60 min)
├── AWS CLI installation
├── kubectl installation
├── eksctl installation
└── Cheatsheets for all tools
    │
    ▼
Activity 3: Console Setup (3-4 hours)
├── Manual EKS cluster creation
├── Understanding every component
├── Deploy monolith Todo app
└── **Learn the hard way**
    │
    ▼
Activity 4: Scripted Setup (2-2.5 hours)
├── eksctl automation
├── Infrastructure as Code
├── Microservices Todo app
└── **Production approach**
    │
    ▼
Activity 5: Advanced Setup (4-5 hours)
├── Horizontal Pod Autoscaler
├── Cluster Autoscaler
├── Application Load Balancer
├── SSL/TLS with ACM
└── **Production-ready patterns**
```

### Time Investment

- **Total Training Time:** 13-17 hours
- **Spread Over:** 3-5 days recommended
- **Hands-on Focus:** 70% practical, 30% theory

---

## 💰 Cost Information

### Activity Costs

| Activity | AWS Resources | Daily Cost | Monthly (if left) |
|----------|--------------|------------|-------------------|
| Activity 1 | None | $0 | $0 |
| Activity 2 | None | $0 | $0 |
| Activity 3 | EKS + 2 nodes | ~$3/day | ~$90/month |
| Activity 4 | EKS + 2 nodes | ~$3/day | ~$90/month |
| Activity 5 | EKS + nodes + ALB | ~$5-7/day | ~$150-210/month |

### Cost Breakdown

```
EKS Control Plane:  $72/month ($2.40/day)
Worker Nodes:       $18/month ($0.60/day) - Spot instances
EBS Volumes:        $3.20/month ($0.11/day)
ALB (Activity 5):   $16/month ($0.53/day)
Data Transfer:      ~$1/month

Minimum Setup: ~$95/month
With ALB: ~$110/month
```

### Cost Optimization

✅ **We use Spot instances** - 70% cheaper than On-Demand  
✅ **Public subnets only** - No NAT Gateway ($32/month saved)  
✅ **Short log retention** - Minimal CloudWatch costs  
✅ **Small instances** - t3.medium suitable for learning  
✅ **Delete when done** - Only pay for active time  

⚠️ **IMPORTANT:** Always delete resources after each activity!

---

## 🗂️ Folder Structure

```
EKS-Training/
│
├── Activity1-Prerequisites/
│   ├── README.md
│   ├── 00-Why-Kubernetes.md
│   ├── 01-Traditional-vs-Cloud-Comparison.md
│   ├── 02-Docker-Basics.md
│   ├── 03-Kubernetes-Concepts.md
│   ├── 04-AWS-Fundamentals.md
│   ├── 05-Networking-Basics.md
│   └── 06-IAM-And-Security.md
│
├── Activity2-Tools-And-Commands/
│   ├── README.md
│   ├── 01-AWS-CLI-Setup.md
│   ├── 02-Kubectl-Setup.md
│   ├── 03-Eksctl-Setup.md
│   ├── 04-AWS-CLI-Cheatsheet.md
│   ├── 05-Kubectl-Cheatsheet.md
│   └── 06-Eksctl-Cheatsheet.md
│
├── Activity3-Console-Setup/
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── 01-VPC-Setup.md
│   ├── 02-IAM-Roles.md
│   ├── 03-EKS-Cluster.md
│   ├── 04-Node-Group.md
│   ├── 05-Deploy-Application.md
│   ├── 06-Testing.md
│   └── 07-CLEANUP.md
│
├── Activity4-Scripted-Setup/
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── cluster-config.yaml
│   ├── 00-Monolith-vs-Microservices-Practice.md
│   ├── 01-Config-Explained.md
│   ├── 02-Eksctl-Deployment.md
│   ├── 03-Deploy-Application.md
│   ├── 04-Verification.md
│   ├── 05-CLEANUP.md
│   ├── cheatsheet.md
│   └── app-manifests/
│       ├── namespace.yaml
│       ├── backend-deployment.yaml
│       ├── backend-service.yaml
│       ├── frontend-deployment.yaml
│       └── frontend-service.yaml
│
├── Activity5-Advanced-Setup/
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── cluster-config-advanced.yaml
│   ├── 01-Metrics-Server.md
│   ├── 02-HPA-Setup.md
│   ├── 03-Cluster-Autoscaler.md
│   ├── 04-ALB-Controller.md
│   ├── 05-Ingress-SSL.md
│   ├── 06-Load-Testing.md
│   ├── 07-CLEANUP.md
│   ├── cheatsheet.md
│   └── app-manifests/
│       ├── backend-hpa.yaml
│       ├── frontend-hpa.yaml
│       └── ingress.yaml
│
└── sample-app/
    ├── backend/
    │   ├── server.js
    │   ├── package.json
    │   ├── Dockerfile
    │   └── README.md
    ├── frontend/
    │   ├── src/
    │   │   ├── App.js
    │   │   ├── TodoList.js
    │   │   └── index.js
    │   ├── package.json
    │   ├── Dockerfile
    │   └── README.md
    └── monolith/
        ├── server.js
        ├── package.json
        ├── Dockerfile
        └── README.md
```

---

## 🚀 Quick Start Guide

### For First-Time Learners

**Day 1: Theory (3-4 hours)**
1. Read Activity 1 - Prerequisites
2. Understand why Kubernetes exists
3. Learn core concepts

**Day 2: Setup (30 min)**
1. Complete Activity 2 - Tools installation
2. Verify all tools work
3. Review cheatsheets

**Day 3: Hands-On Console (3-4 hours)**
1. Complete Activity 3 - Console Setup
2. Create cluster manually
3. **Delete everything when done**

**Day 4: Automation (2-2.5 hours)**
1. Complete Activity 4 - Scripted Setup
2. See automation benefits
3. **Delete cluster when done**

**Day 5: Production Patterns (4-5 hours)**
1. Complete Activity 5 - Advanced Setup
2. Learn auto-scaling and load balancing
3. **Delete everything when done**

### For Experienced Users

**Fast Track (6-8 hours total):**
1. Skim Activity 1 (review concepts)
2. Install tools (Activity 2)
3. **Skip Activity 3** or just read it
4. Start with Activity 4 (scripted approach)
5. Complete Activity 5 (advanced features)

---

## 💡 Key Learning Principles

### 1. Hands-On First

```
70% Practical + 30% Theory = Better Learning

You'll:
✅ Create real clusters
✅ Deploy real applications
✅ Make real mistakes
✅ Fix real problems
```

### 2. Bridge from Traditional

```
Every concept explained with familiar analogies:
- VPS → EC2 Instance
- cPanel → Kubernetes Dashboard
- SSH → kubectl exec
- iptables → Security Groups
- nginx config → Kubernetes Service
```

### 3. Cost Awareness

```
Every activity mentions:
- What it costs
- Why it costs
- How to optimize
- When to delete
```

### 4. Progressive Complexity

```
Activity 3: Manual (understand details)
     ↓
Activity 4: Automated (production approach)
     ↓
Activity 5: Advanced (scale and production-ready)
```

---

## 📖 How to Use This Training

### Reading the Guides

Each guide includes:

```markdown
🏢 Traditional Way:
   How you'd do this with VPS/servers

☁️ AWS Way:
   How we do it in the cloud

💡 Why It Matters:
   Benefits and trade-offs

⚠️ Watch Out:
   Common mistakes to avoid

✅ Success Criteria:
   How to verify it worked
```

### Following Activities

1. **Read the entire activity README first**
2. **Review ARCHITECTURE.md** to understand what you're building
3. **Follow numbered guides in order**
4. **Don't skip steps** (even if you think you know)
5. **Complete cleanup** before moving to next activity

### Using Cheatsheets

Keep these open in browser tabs:
- Activity 2: AWS CLI Cheatsheet
- Activity 2: kubectl Cheatsheet
- Activity 2: eksctl Cheatsheet

---

## 🎓 What You'll Learn

### AWS Services

- **EKS**: Managed Kubernetes service
- **EC2**: Virtual machines for worker nodes
- **VPC**: Virtual private networking
- **IAM**: Identity and access management
- **EBS**: Block storage for persistent volumes
- **CloudWatch**: Logging and monitoring
- **ALB**: Application load balancing
- **ACM**: SSL/TLS certificate management

### Kubernetes Concepts

- **Pods**: Smallest deployable units
- **Deployments**: Declarative updates for Pods
- **Services**: Stable network endpoints
- **ConfigMaps & Secrets**: Configuration management
- **Namespaces**: Virtual clusters
- **HPA**: Horizontal Pod Autoscaler
- **Ingress**: HTTP/HTTPS routing

### DevOps Practices

- Infrastructure as Code (IaC)
- Declarative configuration
- GitOps workflows
- Auto-scaling strategies
- High availability patterns
- Cost optimization
- Security best practices

---

## ⚠️ Important Notes

### Before You Start

1. **Set a budget alert** in AWS ($50/month recommended)
2. **Have admin AWS access** or permissions for EKS, EC2, VPC, IAM
3. **Schedule uninterrupted time** for each activity
4. **Backup important work** (if using existing AWS account)

### During Training

1. **Follow cleanup steps** - Don't skip them!
2. **Tag all resources** - Use `Project: EKS-Training`
3. **Stay in one region** - ap-southeast-1 throughout
4. **Save error messages** - Screenshot errors for troubleshooting

### After Each Activity

1. **Delete all resources** - Follow cleanup guides
2. **Verify deletion** - Check AWS Console
3. **Check billing** - Ensure no ongoing charges
4. **Document learnings** - Take notes on what you learned

---

## 🆘 Help & Support

### Troubleshooting

Each activity has detailed troubleshooting sections. Common issues:

**Can't create cluster:**
- Check IAM permissions
- Verify AWS CLI configuration
- Check service quotas

**Nodes not joining:**
- Verify security group rules
- Check IAM node role
- Review CloudWatch logs

**Application not accessible:**
- Check service type (NodePort)
- Verify security group allows traffic
- Check pod logs

### Getting Help

1. **Read error messages carefully**
2. **Check AWS CloudWatch logs**
3. **Review kubectl events**: `kubectl get events`
4. **Search AWS documentation**
5. **Check EKS Workshop**: https://www.eksworkshop.com/

---

## 📊 Progress Tracking

Use this checklist to track your progress:

- [ ] Activity 1: Prerequisites completed
- [ ] Activity 2: Tools installed and verified
- [ ] Activity 3: Manual cluster created and deleted
- [ ] Activity 4: Scripted cluster created and deleted
- [ ] Activity 5: Advanced features implemented and deleted
- [ ] Understand when to use Kubernetes
- [ ] Comfortable with kubectl commands
- [ ] Can troubleshoot common issues
- [ ] Know how to optimize costs

---

## 🎯 Success Metrics

You've successfully completed the training when you can:

✅ Explain Kubernetes benefits and trade-offs  
✅ Create an EKS cluster using eksctl  
✅ Deploy applications to Kubernetes  
✅ Troubleshoot common issues  
✅ Implement auto-scaling  
✅ Set up load balancing with SSL  
✅ Understand cost implications  
✅ Know when NOT to use Kubernetes  

---

## 🚀 What's Next?

After completing this training:

1. **Practice**: Deploy your own applications
2. **Explore**: Try different Kubernetes features
3. **Advanced Topics**:
   - Service Mesh (Istio, Linkerd)
   - GitOps (ArgoCD, Flux)
   - Monitoring (Prometheus, Grafana)
   - CI/CD Integration
4. **Certifications**: Consider AWS or CNCF certifications
5. **Community**: Join Kubernetes Slack, attend meetups

---

## 📚 Additional Resources

### Official Documentation

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [eksctl Documentation](https://eksctl.io/)

### Learning Resources

- [EKS Workshop](https://www.eksworkshop.com/)
- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

### Community

- [Kubernetes Slack](https://slack.kubernetes.io/)
- [AWS Forums](https://forums.aws.amazon.com/)
- [r/kubernetes](https://www.reddit.com/r/kubernetes/)

---

## 📝 Feedback & Improvements

This training is designed to be practical and beginner-friendly. If you:

- Find errors or outdated information
- Have suggestions for improvements
- Want additional topics covered
- Successfully complete the training

Please share your feedback!

---

## 📄 License & Usage

This training material is provided for educational purposes. Feel free to:

- Use for personal learning
- Share with your team
- Adapt for your organization
- Contribute improvements

---

**Ready to start your cloud-native journey?**

👉 **Begin with:** [Activity1-Prerequisites/README.md](Activity1-Prerequisites/README.md)

**Remember:**
- Take your time
- Understand before moving forward
- Delete resources after each activity
- Have fun learning! 🎓

---

**From traditional servers to cloud-native Kubernetes - You've got this!** 🚀

