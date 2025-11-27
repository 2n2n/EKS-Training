# Activity 1: Prerequisites - Understanding the Fundamentals

Welcome to Activity 1! Before diving into AWS and Kubernetes, we need to build a strong foundation. This activity is designed especially for those coming from traditional hosting and monolith architectures.

---

## 🎯 Learning Objectives

By the end of this activity, you will understand:

- Why Kubernetes exists and what problems it solves
- How cloud-native differs from traditional hosting
- Core Docker and container concepts
- Essential Kubernetes architecture and components
- AWS fundamentals (VPC, EC2, IAM)
- Networking basics for cloud environments
- Security concepts and IAM roles

---

## 👥 Who Is This For?

This training is designed for:

- **Traditional Hosting Users**: If you're familiar with VPS, dedicated servers, cPanel, or Plesk
- **Monolith Developers**: If you deploy applications as single units to one server
- **System Administrators**: Managing servers manually with SSH
- **DevOps Beginners**: Looking to modernize infrastructure
- **AWS Newcomers**: Little to no cloud experience

**What you should already know:**
- Basic Linux/server administration
- How to SSH into a server
- Basic networking concepts (IP addresses, ports)
- How to deploy applications (even if manually)

---

## ⏱️ Time Estimate

**Total Time: 3-4 hours**

This is reading and learning time - no AWS costs incurred!

| Document | Topic | Time |
|----------|-------|------|
| 00 | Why Kubernetes? | 30 min |
| 01 | Traditional vs Cloud Comparison | 30 min |
| 02 | Docker Basics | 30 min |
| 03 | Kubernetes Concepts | 45 min |
| 04 | AWS Fundamentals | 30 min |
| 05 | Networking Basics | 30 min |
| 06 | IAM and Security | 30 min |

**Pro Tip**: Don't rush! Take breaks between documents. Understanding these concepts will make the hands-on activities much easier.

---

## 📚 Reading Order

### Start Here (Recommended Path)

1. **[00-Why-Kubernetes.md](00-Why-Kubernetes.md)** - Start here!
   - Understand the "why" before the "how"
   - See if Kubernetes is right for your use case
   - Learn about monolith vs microservices

2. **[01-Traditional-vs-Cloud-Comparison.md](01-Traditional-vs-Cloud-Comparison.md)**
   - Bridge your existing knowledge to cloud concepts
   - Learn the new terminology with familiar analogies

3. **[02-Docker-Basics.md](02-Docker-Basics.md)**
   - Understand containers (the building blocks)
   - How they differ from VMs

4. **[03-Kubernetes-Concepts.md](03-Kubernetes-Concepts.md)**
   - Core Kubernetes architecture
   - Pods, Services, Deployments explained

5. **[04-AWS-Fundamentals.md](04-AWS-Fundamentals.md)**
   - Essential AWS services for EKS
   - VPC, EC2, IAM basics

6. **[05-Networking-Basics.md](05-Networking-Basics.md)**
   - Cloud networking concepts
   - Subnets, security groups, routing

7. **[06-IAM-And-Security.md](06-IAM-And-Security.md)**
   - AWS IAM roles and policies
   - Security best practices

---

## 💡 Learning Tips

### For Traditional Hosting Users

If you're coming from cPanel, Plesk, or manual server management:

- **Don't worry!** Everything you know is still valuable
- We'll use analogies to connect old concepts to new ones
- Think of Kubernetes as "automated server management at scale"
- Your networking and Linux knowledge will help a lot

### Study Approach

1. **Read actively**: Take notes, draw diagrams
2. **Ask questions**: Write down what confuses you
3. **Connect concepts**: Link new ideas to what you already know
4. **Take breaks**: This is a lot of new information
5. **Don't memorize**: Focus on understanding concepts

### Common Questions We'll Answer

- "Why can't I just use my VPS like always?"
- "Isn't this too complex for my small app?"
- "What's wrong with SSH and manual deployment?"
- "Do I really need all this for a simple website?"

These are great questions! We'll address them all.

---

## 🎓 What You'll Understand

### By Document

**00 - Why Kubernetes**
- Problems with traditional deployment methods
- How Kubernetes solves scaling, reliability, deployment
- When to use (and not use) Kubernetes
- Monolith vs microservices trade-offs

**01 - Traditional vs Cloud**
- Mental model: Old way → New way
- Terminology mapping (e.g., "Security Groups" = "Firewall rules")
- Why cloud-native architecture exists

**02 - Docker Basics**
- What containers actually are
- Containers vs VMs (and when to use each)
- How Docker simplifies deployments
- Writing a basic Dockerfile

**03 - Kubernetes Concepts**
- Cluster architecture (control plane + worker nodes)
- Pods: The smallest deployable unit
- Services: Internal load balancing
- Deployments: Declarative application management

**04 - AWS Fundamentals**
- AWS regions and availability zones
- EC2: Virtual servers in the cloud
- VPC: Your private network
- IAM: Managing permissions

**05 - Networking Basics**
- IP addressing and CIDR notation
- Public vs private subnets
- Internet gateways and NAT
- Security groups and network ACLs

**06 - IAM and Security**
- IAM roles vs users
- Service roles for EKS
- Least privilege principle
- Managing access securely

---

## 🚫 What You WON'T Do (Yet)

- **No AWS account needed** (yet - that comes in Activity 2)
- **No installations** (that's Activity 2)
- **No costs** (this is pure learning)
- **No hands-on labs** (coming in Activities 3-5)

This activity is 100% conceptual learning. Hands-on work starts in Activity 3!

---

## ✅ Success Criteria

You're ready for Activity 2 when you can answer:

- [ ] What problems does Kubernetes solve that my current setup doesn't?
- [ ] How do containers differ from VMs?
- [ ] What's the difference between a Pod and a Deployment?
- [ ] What is a VPC and why do I need one?
- [ ] What are Security Groups used for?
- [ ] What's an IAM role and how is it different from a user?
- [ ] When should I NOT use Kubernetes?

**Don't worry about memorizing details** - just understand the concepts!

---

## 🔄 Coming From Traditional Hosting?

### You Might Be Thinking...

**"This seems complicated compared to my current setup"**
- You're right! It is more complex initially
- But it solves problems that appear as you scale
- Small apps might not need this (we discuss when NOT to use K8s)

**"I just SSH and deploy, why change?"**
- Manual deployment doesn't scale beyond a few servers
- Zero-downtime deployments are hard manually
- Kubernetes automates what you do manually

**"My app works fine as a monolith"**
- Monoliths are perfectly valid!
- We'll show both approaches (Activity 3: monolith, Activity 4: microservices)
- You decide what's best for your use case

### What You'll Gain

- **Automation**: Deploy with one command, not 20 SSH sessions
- **Reliability**: Auto-healing, auto-scaling, auto-restart
- **Consistency**: Same deployment process every time
- **Scalability**: Go from 1 to 100 servers easily
- **Modern skills**: Industry-standard cloud-native practices

---

## 📖 Next Steps

1. Start with **[00-Why-Kubernetes.md](00-Why-Kubernetes.md)**
2. Read through all documents in order
3. Take notes and highlight confusing parts
4. Move to **Activity 2** when comfortable

---

## 💬 Need Help?

- Re-read confusing sections
- Draw diagrams to visualize concepts
- Look up terms you don't understand
- Remember: Everyone finds this complex at first!

---

**Ready to begin?** Open [00-Why-Kubernetes.md](00-Why-Kubernetes.md) and let's start understanding why Kubernetes exists!

Remember: **No AWS costs for this activity** - just learning! ☕

