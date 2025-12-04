# Root Setup 06: Grant Participant Access

**For:** Workshop Administrator (Root Account)  
**Time:** 15 minutes  
**Cost Impact:** $0 (no additional cost)

Configure the cluster to allow all 7 workshop participants to access and manage it.

---

## 🎯 What You'll Do

- Edit aws-auth ConfigMap to add participant IAM users
- Map participants to system:masters group (full admin access)
- Test access with one participant account
- Provide connection instructions to participants

---

## 📋 Prerequisites

- [ ] Completed previous ROOT-SETUP steps (01-05)
- [ ] Cluster is Active with nodes Ready
- [ ] kubectl configured and working
- [ ] Have participant IAM user ARNs ready

---

## Understanding Kubernetes RBAC

**Two Permission Layers:**

```
IAM (AWS Level):
└── Controls: Can user access AWS APIs?
    └── Already configured via EKSWorkshopPolicy

RBAC (Kubernetes Level):
└── Controls: What can user do IN the cluster?
    └── Configured via aws-auth ConfigMap (this guide!)
```

**aws-auth ConfigMap:**

- Maps IAM identities to Kubernetes roles
- Required for anyone except cluster creator
- Lives in kube-system namespace

---

## Step 1: Get Participant IAM User ARNs

You need the ARN for each participant's IAM user.

### Get All Participant ARNs

```bash
# List all workshop participant users
aws iam list-users \
    --query 'Users[?starts_with(UserName, `eks-`)].{Name:UserName,ARN:Arn}' \
    --output table

# Or get ARNs for specific users:
PARTICIPANTS=("charles" "joshua" "robert" "sharmaine" "daniel" "jett" "thon")

for name in "${PARTICIPANTS[@]}"; do
    echo "eks-$name:"
    aws iam get-user \
        --user-name "eks-$name" \
        --query 'User.Arn' \
        --output text
done
```

**Save these ARNs!** Format:

```
arn:aws:iam::<account-id>:user/eks-charles
arn:aws:iam::<account-id>:user/eks-joshua
arn:aws:iam::<account-id>:user/eks-robert
arn:aws:iam::<account-id>:user/eks-sharmaine
arn:aws:iam::<account-id>:user/eks-daniel
arn:aws:iam::<account-id>:user/eks-jett
arn:aws:iam::<account-id>:user/eks-thon
```

---

## Step 2: View Current aws-auth ConfigMap

Check the current configuration:

```bash
# View current aws-auth
kubectl get configmap aws-auth -n kube-system -o yaml

# Save a backup first!
kubectl get configmap aws-auth -n kube-system -o yaml > aws-auth-backup.yaml
```

**Current content** (approximately):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::<account-id>:role/eks-workshop-node-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

**What this does:**

- Maps node IAM role to Kubernetes system:node
- Allows nodes to join cluster
- **Don't modify this part!**

---

## Step 3: Create Updated aws-auth ConfigMap

### Option A: Edit Directly (Simple)

```bash
# Edit the ConfigMap
kubectl edit configmap aws-auth -n kube-system
```

**Add `mapUsers` section** under `data:` (after `mapRoles:`):

```yaml
data:
  mapRoles: |
    - rolearn: arn:aws:iam::<account-id>:role/eks-workshop-node-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::<account-id>:user/eks-charles
      username: charles
      groups:
        - system:masters
    - userarn: arn:aws:iam::<account-id>:user/eks-joshua
      username: joshua
      groups:
        - system:masters
    - userarn: arn:aws:iam::<account-id>:user/eks-robert
      username: robert
      groups:
        - system:masters
    - userarn: arn:aws:iam::<account-id>:user/eks-sharmaine
      username: sharmaine
      groups:
        - system:masters
    - userarn: arn:aws:iam::<account-id>:user/eks-daniel
      username: daniel
      groups:
        - system:masters
    - userarn: arn:aws:iam::<account-id>:user/eks-jett
      username: jett
      groups:
        - system:masters
    - userarn: arn:aws:iam::<account-id>:user/eks-thon
      username: thon
      groups:
        - system:masters
```

Save and exit the editor (`:wq` in vim or save in nano)

---

### Option B: Apply Complete File (Safer)

Create a complete aws-auth file:

```bash
# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the complete ConfigMap file
cat > aws-auth-complete.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::${ACCOUNT_ID}:role/eks-workshop-node-role
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-charles
      username: charles
      groups:
        - system:masters
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-joshua
      username: joshua
      groups:
        - system:masters
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-robert
      username: robert
      groups:
        - system:masters
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-sharmaine
      username: sharmaine
      groups:
        - system:masters
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-daniel
      username: daniel
      groups:
        - system:masters
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-jett
      username: jett
      groups:
        - system:masters
    - userarn: arn:aws:iam::${ACCOUNT_ID}:user/eks-thon
      username: thon
      groups:
        - system:masters
EOF

# Apply the ConfigMap
kubectl apply -f aws-auth-complete.yaml
```

---

## Step 4: Verify ConfigMap Update

```bash
# View updated ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Should see both mapRoles and mapUsers sections

# Check specific user mapping
kubectl get configmap aws-auth -n kube-system -o yaml | grep -A 3 "charles"
```

---

## Step 5: Test Participant Access

Test with ONE participant before telling everyone.

### Get Participant Credentials

You need a participant's access key and secret key (from credentials CSV).

### Test on Your Machine (Temporary Profile)

```bash
# Create temporary AWS profile
aws configure --profile test-participant

# Enter when prompted:
AWS Access Key ID: <charles-access-key-id>
AWS Secret Access Key: <charles-secret-access-key>
Default region: ap-southeast-1
Default output format: json

# Update kubeconfig with participant credentials
aws eks update-kubeconfig \
    --name shared-workshop-cluster \
    --region ap-southeast-1 \
    --profile test-participant

# Test kubectl access
kubectl get nodes --as-user=charles

# Expected output: 2 nodes with STATUS=Ready

# Test creating resources
kubectl get namespaces

# Should list all namespaces (confirms system:masters access)

# Clean up test profile
aws configure --profile test-participant list
rm ~/.aws/credentials # Be careful! Or manually edit
```

---

## ⚠️ Understanding system:masters Group

**What is system:masters?**

- Built-in Kubernetes admin group
- Has FULL cluster access
- Can do ANYTHING in the cluster
- Bypasses all authorization checks

**Permissions granted:**

```
With system:masters, participants CAN:
✅ Create/delete any resources
✅ Access all namespaces
✅ Modify system components
✅ Delete the cluster (via AWS)
✅ Everything

Participants CANNOT (AWS-level restrictions):
❌ Access your root account
❌ Modify IAM (unless granted separately)
❌ Access other AWS services (unless granted)
```

**Why give this level of access?**

- Learning environment (not production)
- Participants need hands-on experience
- Teaches responsibility
- Simulates real admin scenarios

---

## 🔒 Alternative: More Restrictive Access (Optional)

For safer workshops, you can create namespace-specific access instead:

### Create Namespace-Specific Roles

```bash
# Create role that can only manage one namespace
cat > namespace-admin-role.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
  namespace: default # Repeat for each participant namespace
rules:
- apiGroups: ["", "apps", "batch", "extensions"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: charles-namespace-admin
  namespace: charles-workspace
subjects:
- kind: User
  name: charles
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: namespace-admin
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f namespace-admin-role.yaml
```

**Then in aws-auth, map to this role instead of system:masters**

**Trade-offs:**

- ✅ More secure (limited blast radius)
- ✅ Participants can't affect others
- ❌ Can't practice cluster-wide operations
- ❌ Can't create node groups
- ❌ More complex to set up

For this workshop, we recommend system:masters for full learning experience.

---

## ✅ Validation Checklist

- [ ] aws-auth ConfigMap updated with mapUsers section
- [ ] All 7 participant IAM users added
- [ ] Each user mapped to system:masters group
- [ ] Tested access with at least one participant
- [ ] Test user can list nodes
- [ ] Test user can list namespaces
- [ ] No errors in ConfigMap

---

## 📧 Notify Participants

Send this information to all participants:

```
Subject: EKS Cluster Ready - Connection Instructions

Hello Workshop Participants!

The shared EKS cluster is ready for you to use!

Cluster Information:
- Name: shared-workshop-cluster
- Region: ap-southeast-1

Connection Instructions:
1. Ensure you have AWS CLI and kubectl installed
2. Configure your AWS credentials:
   aws configure
   (Use the Access Key ID and Secret Access Key from the CSV file)

3. Connect to the cluster:
   aws eks update-kubeconfig --name shared-workshop-cluster --region ap-southeast-1

4. Verify connection:
   kubectl get nodes
   (You should see 2 nodes)

5. Start with the guides:
   Begin at: PARTICIPANT-GUIDES/01-CONNECT-TO-CLUSTER.md

Important:
- READ SAFETY-GUIDELINES.md before doing anything!
- You have full admin access - use it responsibly
- Work in your personal namespace: <your-name>-workspace
- Prefix all resources with your name
- Communicate before major changes

Questions? Ask in the team chat or contact me.

Happy learning!
- Workshop Admin
```

---

## 🚨 Troubleshooting

### Issue: Participant Gets "Unauthorized"

**Error:** "error: You must be logged in to the server (Unauthorized)"

**Check 1: ConfigMap syntax**

```bash
# Validate YAML syntax
kubectl get configmap aws-auth -n kube-system -o yaml | kubectl apply --dry-run=client -f -
```

**Check 2: User ARN correct**

```bash
# Verify ARN matches exactly
kubectl get configmap aws-auth -n kube-system -o yaml | grep "eks-charles"

# Compare with actual ARN
aws iam get-user --user-name eks-charles --query 'User.Arn'
```

**Check 3: Participant using correct AWS credentials**

```bash
# Participant should run:
aws sts get-caller-identity

# Should show their IAM user ARN
```

---

### Issue: ConfigMap Update Failed

**Error:** "error: configmaps 'aws-auth' is invalid"

**Solution:**

```bash
# Restore from backup
kubectl apply -f aws-auth-backup.yaml

# Check YAML syntax (indentation matters!)
# Recreate with correct syntax
```

---

### Issue: Nodes Become NotReady After Update

**If you accidentally broke mapRoles:**

```bash
# Quickly restore backup!
kubectl apply -f aws-auth-backup.yaml

# Nodes should recover in 1-2 minutes
```

**Prevention:**

- Always backup before editing
- Don't modify mapRoles section
- Only add mapUsers section

---

## 🎓 What You've Accomplished

```
✅ Configured cluster access for all participants
✅ Mapped IAM users to Kubernetes permissions
✅ Granted full admin access (system:masters)
✅ Tested access with participant credentials
✅ Cluster ready for workshop!

Setup Complete!
├── VPC and networking ✅
├── IAM roles ✅
├── EKS cluster ✅
├── Worker nodes ✅
├── ECR repository ✅
└── Participant access ✅

All 7 participants can now:
├── Connect with kubectl
├── View and manage resources
├── Deploy applications
├── Create namespaces
├── Manage nodes
└── Full cluster administration
```

---

## 🚀 Next Steps

**Setup is complete!** 🎉

1. **Inform participants** - Send connection instructions
2. **Direct them to:**

   - [00-SETUP-PREREQUISITES.md](../00-SETUP-PREREQUISITES.md) for tools
   - [SAFETY-GUIDELINES.md](../SAFETY-GUIDELINES.md) ⚠️ CRITICAL!
   - [PARTICIPANT-GUIDES/](../PARTICIPANT-GUIDES/) for learning

3. **Monitor cluster:**

```bash
# Watch cluster activity
kubectl get events --all-namespaces --watch

# Monitor resource usage
kubectl top nodes

# See what participants are creating
kubectl get all --all-namespaces
```

4. **Be available for questions** during workshop

5. **After workshop:** Follow [../CLEANUP-GUIDE.md](../CLEANUP-GUIDE.md)

---

## 📚 Additional Resources

- [Managing Users with aws-auth](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [EKS Best Practices - IAM](https://aws.github.io/aws-eks-best-practices/security/docs/iam/)
- [system:masters Group](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
