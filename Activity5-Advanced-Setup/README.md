# Activity 5: Advanced Setup - Production-Ready Patterns

Welcome to Activity 5! This is where you learn production-grade Kubernetes features: auto-scaling, load balancing, and SSL/TLS.

---

## 🎯 Learning Objectives

By the end of this activity, you will:

- ✅ Implement Horizontal Pod Autoscaler (HPA)
- ✅ Configure Cluster Autoscaler
- ✅ Deploy AWS Load Balancer Controller
- ✅ Set up Application Load Balancer (ALB)
- ✅ Configure SSL/TLS with AWS Certificate Manager
- ✅ Understand production-ready patterns
- ✅ Test auto-scaling under load

---

## ⏱️ Time Estimate

**Total Time: 4-5 hours**

| Step | Task | Time |
|------|------|------|
| 01 | Install Metrics Server | 20 min |
| 02 | Configure HPA | 30 min |
| 03 | Setup Cluster Autoscaler | 40 min |
| 04 | Install ALB Controller | 40 min |
| 05 | Configure Ingress with SSL | 40 min |
| 06 | Load Testing | 30 min |
| 07 | Cleanup | 15 min |

**Active time:** ~3-3.5 hours  
**Wait time:** ~20 minutes  
**Testing:** ~30 minutes  
**Cleanup:** ~15 minutes

---

## 💰 Cost Warning

**This activity costs MORE!**

```
Compared to Activities 3-4:
├── EKS Control Plane: $0.10/hour ($2.40/day) - Same
├── EC2 Nodes: $0.025/hour base ($0.60/day) - Same
├── ALB: $0.0225/hour ($0.54/day) - NEW!
├── Additional nodes during scaling: Variable
├── Data Transfer (ALB): Minimal for testing
└── Total: ~$5-7/day (~$0.20-0.30/hour)

Monthly if left running: ~$150-210
```

**⚠️ CRITICAL:** Delete ALB and cluster when done!

---

## 🏗️ What You'll Build

```
┌─────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)            │
│              https://your-domain.com                    │
│              SSL Certificate (ACM)                      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│            Ingress Controller                           │
│            Routes traffic to services                   │
└─────────────────────────────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ Frontend Service │    │ Backend Service  │
    │                  │    │                  │
    │ HPA: 2-10 pods   │    │ HPA: 2-10 pods   │
    │ Auto-scales      │    │ Auto-scales      │
    └──────────────────┘    └──────────────────┘

Cluster Autoscaler:
- Monitors pod resource requests
- Adds nodes when pods can't be scheduled
- Removes nodes when underutilized
- Min: 2 nodes, Max: 5 nodes
```

---

## 🚀 Advanced Features

### 1. Horizontal Pod Autoscaler (HPA)

**What:** Automatically scale pods based on CPU/memory usage

```
Load increases → CPU > 70% → Add more pods
Load decreases → CPU < 30% → Remove pods

Scales between:
- Min: 2 pods
- Max: 10 pods
```

### 2. Cluster Autoscaler

**What:** Automatically scale nodes based on pod requirements

```
Pods pending (not enough resources) → Add node
Nodes underutilized → Remove node

Scales between:
- Min: 2 nodes
- Max: 5 nodes
```

### 3. Application Load Balancer (ALB)

**What:** AWS-managed load balancer with advanced features

```
Benefits:
✅ Layer 7 load balancing (HTTP/HTTPS)
✅ SSL/TLS termination
✅ Path-based routing
✅ Host-based routing
✅ Health checks
✅ AWS-managed (high availability)
```

### 4. SSL/TLS with ACM

**What:** Free SSL certificates from AWS

```
Features:
✅ Automatic renewal
✅ No cost
✅ Trusted by browsers
✅ Easy integration with ALB
```

---

## 📚 Files in This Activity

```
Activity5-Advanced-Setup/
├── README.md
├── ARCHITECTURE.md
├── cluster-config-advanced.yaml
├── 01-Metrics-Server.md
├── 02-HPA-Setup.md
├── 03-Cluster-Autoscaler.md
├── 04-ALB-Controller.md
├── 05-Ingress-SSL.md
├── 06-Load-Testing.md
├── 07-CLEANUP.md
├── cheatsheet.md
└── app-manifests/
    ├── backend-hpa.yaml
    ├── frontend-hpa.yaml
    └── ingress.yaml
```

---

## 🎯 Quick Start

**Prerequisites:**
- Completed Activity 4 (or understand eksctl)
- Domain name (optional, can test without)
- AWS Route 53 (optional, for SSL)

```bash
# 1. Create cluster with advanced config
eksctl create cluster -f cluster-config-advanced.yaml

# 2. Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3. Deploy application with HPA
kubectl apply -f app-manifests/

# 4. Install AWS Load Balancer Controller
# (Follow guide 04-ALB-Controller.md)

# 5. Create Ingress
kubectl apply -f app-manifests/ingress.yaml

# 6. Test auto-scaling
# (Follow guide 06-Load-Testing.md)

# 7. Cleanup
eksctl delete cluster --name training-cluster-advanced --region ap-southeast-1
```

---

## 💡 Production Patterns You'll Learn

### 1. Resource-Based Auto-Scaling

```yaml
HPA based on:
├── CPU utilization
├── Memory utilization
└── Custom metrics (advanced)

Automatically maintains:
├── Performance under load
├── Cost optimization (scale down)
└── Reliability (scale up)
```

### 2. Infrastructure Auto-Scaling

```yaml
Cluster Autoscaler:
├── Node provisioning
├── Node termination
└── Cost optimization

Benefits:
├── Never run out of capacity
├── Pay only for what you need
└── Fully automated
```

### 3. Advanced Load Balancing

```yaml
ALB features:
├── Path routing: /api → backend
├── Host routing: api.domain.com → backend
├── SSL termination
├── Health checks
└── Auto-scaling integration
```

### 4. Security Best Practices

```yaml
SSL/TLS:
├── HTTPS only
├── Certificate management
├── Automatic renewal
└── Industry standard
```

---

## 🆚 Comparison with Previous Activities

| Feature | Activity 3-4 | Activity 5 |
|---------|-------------|-----------|
| **Scaling** | Manual | Automatic |
| **Load Balancer** | NodePort | ALB |
| **SSL/TLS** | No | Yes |
| **Production Ready** | No | Yes ✅ |
| **Cost** | ~$3/day | ~$5-7/day |
| **Complexity** | Basic | Advanced |

---

## ✅ Success Criteria

You've completed Activity 5 when:

- [ ] Metrics-server running
- [ ] HPA configured for frontend and backend
- [ ] Cluster Autoscaler deployed
- [ ] ALB Controller installed
- [ ] Application accessible via ALB
- [ ] SSL/TLS configured (if using domain)
- [ ] Auto-scaling tested and verified
- [ ] **Everything deleted (including ALB!)**

---

## ⚠️ Important Notes

### Before Starting

1. **Budget:** This costs more (~$5-7/day)
2. **Time:** Need 4-5 hours
3. **Domain:** Optional but recommended for SSL
4. **Previous Activities:** Should understand Activities 1-4

### During Activity

1. **Monitor costs:** ALB adds $0.54/day + data transfer
2. **Test scaling:** Actually generate load to see it work
3. **Understand concepts:** Don't just copy-paste

### After Completion

1. **Delete ALB first:** Before deleting cluster
2. **Delete cluster:** `eksctl delete cluster`
3. **Verify deletion:** Check AWS Console
4. **Check billing:** Ensure no ongoing charges

---

## 🎓 What Makes This "Production-Ready"

### Reliability

```
✅ Auto-healing (pods restart)
✅ Auto-scaling (handle traffic spikes)
✅ Load balancing (distribute traffic)
✅ Health checks (detect failures)
✅ Multi-AZ (high availability)
```

### Performance

```
✅ Scales with demand
✅ Resource optimization
✅ Efficient load distribution
✅ Fast response times
```

### Security

```
✅ HTTPS/SSL encryption
✅ Certificate management
✅ Security groups
✅ IAM roles
```

### Operations

```
✅ Automated operations
✅ Monitoring (metrics-server)
✅ Logging (CloudWatch)
✅ Infrastructure as Code
```

---

## 🚀 After This Activity

You'll be able to:

- ✅ Deploy production-grade applications
- ✅ Implement auto-scaling strategies
- ✅ Configure load balancing
- ✅ Manage SSL/TLS certificates
- ✅ Handle traffic spikes automatically
- ✅ Optimize costs with auto-scaling
- ✅ Troubleshoot complex issues

**Next Steps:**
- Apply these patterns to your own applications
- Explore service mesh (Istio, Linkerd)
- Learn GitOps (ArgoCD, Flux)
- Study monitoring (Prometheus, Grafana)

---

## 📖 Resources

- [HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

---

**Ready for production patterns?** Start with [01-Metrics-Server.md](01-Metrics-Server.md)!

**Remember:** This is how real production clusters work! 🚀

