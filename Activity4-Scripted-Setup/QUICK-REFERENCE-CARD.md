# Activity 4 - Quick Reference Card

**Print this or keep it open!** 📋

---

## 👤 My Information

```
IAM Username: eks-_______
Short Name: _______
Cluster Name: eks-_______-cluster
Node Group: _______-nodes
Namespace: _______-todo-app
```

---

## 🚀 Quick Start Commands

### 1. Personalize Files

```bash
# Set your username
export MY_USERNAME="____"  # Your name!

# Navigate to directory
cd /path/to/Activity4-Scripted-Setup

# Replace CHANGEME
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/*.yaml

# Validate
./validate-personalization.sh
```

### 2. Create Cluster

```bash
# Create cluster
eksctl create cluster -f cluster-config.yaml

# Wait 20 minutes ☕
```

### 3. Deploy Application

```bash
# Deploy to your namespace
kubectl apply -f app-manifests/

# Check pods
kubectl get pods -n ${MY_USERNAME}-todo-app

# Check services
kubectl get svc -n ${MY_USERNAME}-todo-app
```

### 4. Access Application

```bash
# Get node IP
kubectl get nodes -o wide

# Access in browser
# http://<NODE-IP>:30080
```

### 5. Cleanup

```bash
# Delete cluster
eksctl delete cluster \
  --name eks-${MY_USERNAME}-cluster \
  --region ap-southeast-1

# Verify deletion
aws eks list-clusters --region ap-southeast-1
```

---

## 🔍 Verification Commands

```bash
# Check cluster status
aws eks describe-cluster \
  --name eks-${MY_USERNAME}-cluster \
  --region ap-southeast-1 \
  --query 'cluster.status'

# Check nodes
kubectl get nodes

# Check pods in YOUR namespace
kubectl get pods -n ${MY_USERNAME}-todo-app

# Check all resources in YOUR namespace
kubectl get all -n ${MY_USERNAME}-todo-app

# View pod logs
kubectl logs -f <POD-NAME> -n ${MY_USERNAME}-todo-app

# Describe pod (troubleshooting)
kubectl describe pod <POD-NAME> -n ${MY_USERNAME}-todo-app
```

---

## 🆘 Troubleshooting

### Issue: Cluster creation fails

```bash
# Check CloudFormation
aws cloudformation list-stacks \
  --region ap-southeast-1 | \
  grep eks-${MY_USERNAME}-cluster

# View events
eksctl utils describe-stacks \
  --cluster=eks-${MY_USERNAME}-cluster \
  --region=ap-southeast-1
```

### Issue: Pods not starting

```bash
# Check pod status
kubectl get pods -n ${MY_USERNAME}-todo-app

# View logs
kubectl logs <POD-NAME> -n ${MY_USERNAME}-todo-app

# Describe pod
kubectl describe pod <POD-NAME> -n ${MY_USERNAME}-todo-app

# Check events
kubectl get events -n ${MY_USERNAME}-todo-app --sort-by='.lastTimestamp'
```

### Issue: Can't access application

```bash
# Check service
kubectl get svc -n ${MY_USERNAME}-todo-app

# Check NodePort
kubectl get svc frontend-service -n ${MY_USERNAME}-todo-app -o jsonpath='{.spec.ports[0].nodePort}'

# Get node IPs
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'

# Check security group
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*eks-${MY_USERNAME}-cluster*" \
  --region ap-southeast-1
```

### Issue: Wrong namespace

```bash
# List all namespaces
kubectl get namespaces

# Your namespace should be: ${MY_USERNAME}-todo-app
# If different, check if you replaced CHANGEME correctly

# Re-validate
./validate-personalization.sh
```

---

## 📊 Monitoring Commands

```bash
# Watch pod status
watch kubectl get pods -n ${MY_USERNAME}-todo-app

# Watch node status
watch kubectl get nodes

# Top nodes (resource usage)
kubectl top nodes

# Top pods (resource usage)
kubectl top pods -n ${MY_USERNAME}-todo-app

# Cluster info
kubectl cluster-info
```

---

## 🎯 Success Checklist

- [ ] Files personalized (no CHANGEME remaining)
- [ ] Validation script passed
- [ ] Cluster created successfully
- [ ] 2 nodes in Ready state
- [ ] Namespace created: `${MY_USERNAME}-todo-app`
- [ ] 2 backend pods Running
- [ ] 2 frontend pods Running
- [ ] frontend-service has NodePort 30080
- [ ] backend-service is ClusterIP
- [ ] Application accessible in browser
- [ ] Todo app is functional
- [ ] Cluster deleted
- [ ] Cleanup verified (no resources remaining)

---

## 💰 Cost Reminder

```
Your cluster costs:
├── EKS Control Plane: $0.10/hour
├── 2x t3.medium Spot: $0.025/hour
└── Total: ~$0.13/hour (~$3.15/day)

⚠️ DELETE when done!
```

---

## 📞 Need Help?

1. Check error messages carefully
2. Review logs: `kubectl logs <POD-NAME> -n ${MY_USERNAME}-todo-app`
3. Verify personalization: `./validate-personalization.sh`
4. Check AWS Console
5. Ask instructor

---

## 🔗 Important Files

| File | Purpose | Must Edit |
|------|---------|-----------|
| 00-PERSONALIZATION-GUIDE.md | Detailed setup | Read |
| validate-personalization.sh | Verify setup | Run |
| cluster-config.yaml | Cluster config | **YES** |
| app-manifests/namespace.yaml | Namespace | **YES** |
| app-manifests/backend-deployment.yaml | Backend | **YES** |
| app-manifests/frontend-deployment.yaml | Frontend | **YES** |

---

## 🌐 Useful URLs

**AWS Console:**
- EKS: https://console.aws.amazon.com/eks/home?region=ap-southeast-1
- CloudFormation: https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1
- EC2 Instances: https://console.aws.amazon.com/ec2/home?region=ap-southeast-1#Instances

**Documentation:**
- eksctl: https://eksctl.io/
- kubectl: https://kubernetes.io/docs/reference/kubectl/
- EKS Best Practices: https://aws.github.io/aws-eks-best-practices/

---

## 📝 Notes Section

Use this space for your own notes:

```
Cluster Created: ________________
Node IPs: ________________
Application URL: ________________
Issues Encountered: ________________
_________________________________
_________________________________
_________________________________
```

---

**Time Started:** ___:___ **Time Completed:** ___:___  
**Duration:** _______ hours

---

**💡 Tip:** Keep this card open in a separate window while working!

