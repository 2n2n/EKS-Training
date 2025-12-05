# Personalization Guide - Activity 4

## 🎯 Purpose

Each of the 7 participants will create their **OWN cluster** with their **OWN namespace**. This guide helps you personalize all configuration files with your assigned IAM username.

---

## 📋 Your Assigned Username

Check which username you've been assigned:

| Participant | IAM Username | Cluster Name       | Namespace       |
| ----------- | ------------ | ------------------ | --------------- |
| 1           | eks-thon     | eks-thon-cluster   | thon-todo-app   |
| 2           | eks-pythia   | eks-pythia-cluster | pythia-todo-app |
| 3           | eks-cronus   | eks-cronus-cluster | cronus-todo-app |
| 4           | eks-rhea     | eks-rhea-cluster   | rhea-todo-app   |
| 5           | eks-atlas    | eks-atlas-cluster  | atlas-todo-app  |
| 6           | eks-helios   | eks-helios-cluster | helios-todo-app |
| 7           | eks-selene   | eks-selene-cluster | selene-todo-app |

---

## 🔍 Step 1: Verify Your IAM Username

```bash
# Check your current IAM identity
aws sts get-caller-identity

# Example output:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/eks-thon"
# }

# Your username is the last part: eks-thon
# Use just the part after 'eks-': thon
```

---

## 🔧 Step 2: Automatic Personalization (Recommended)

### For macOS/Linux:

```bash
# 1. Navigate to Activity 4 directory
cd /path/to/EKS-Training/Activity4-Scripted-Setup

# 2. Set your username (CHANGE THIS!)
export MY_USERNAME="thon"  # Replace 'thon' with YOUR username

# 3. Backup original files (optional but recommended)
cp cluster-config.yaml cluster-config.yaml.original
cp app-manifests/namespace.yaml app-manifests/namespace.yaml.original
cp app-manifests/backend-deployment.yaml app-manifests/backend-deployment.yaml.original
cp app-manifests/frontend-deployment.yaml app-manifests/frontend-deployment.yaml.original

# 4. Replace CHANGEME with your username in all files
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/namespace.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/backend-deployment.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/frontend-deployment.yaml

# 5. Verify changes
echo "Checking cluster-config.yaml:"
grep "name: eks-" cluster-config.yaml | head -1

echo "Checking namespace.yaml:"
grep "name: " app-manifests/namespace.yaml | head -1

echo "Checking backend-deployment.yaml:"
grep "namespace: " app-manifests/backend-deployment.yaml | head -1

echo "Checking frontend-deployment.yaml:"
grep "namespace: " app-manifests/frontend-deployment.yaml | head -1

# Expected output:
# name: eks-thon-cluster
# name: thon-todo-app
# namespace: thon-todo-app
# namespace: thon-todo-app
```

### For Windows (PowerShell):

```powershell
# 1. Navigate to Activity 4 directory
cd C:\path\to\EKS-Training\Activity4-Scripted-Setup

# 2. Set your username (CHANGE THIS!)
$MY_USERNAME = "thon"  # Replace 'thon' with YOUR username

# 3. Replace CHANGEME in all files
(Get-Content cluster-config.yaml) -replace 'CHANGEME', $MY_USERNAME | Set-Content cluster-config.yaml
(Get-Content app-manifests\namespace.yaml) -replace 'CHANGEME', $MY_USERNAME | Set-Content app-manifests\namespace.yaml
(Get-Content app-manifests\backend-deployment.yaml) -replace 'CHANGEME', $MY_USERNAME | Set-Content app-manifests\backend-deployment.yaml
(Get-Content app-manifests\frontend-deployment.yaml) -replace 'CHANGEME', $MY_USERNAME | Set-Content app-manifests\frontend-deployment.yaml

# 4. Verify changes
Select-String -Path cluster-config.yaml -Pattern "name: eks-"
Select-String -Path app-manifests\namespace.yaml -Pattern "name: "
```

---

## ✏️ Step 3: Manual Personalization (Alternative)

If you prefer to edit files manually:

### File 1: `cluster-config.yaml`

Find and replace ALL occurrences:

- `eks-CHANGEME-cluster` → `eks-thon-cluster` (your username)
- `CHANGEME-nodes` → `thon-nodes`
- `Owner: CHANGEME` → `Owner: thon`

**Lines to change:** 7, 14, 25, 51, 53

### File 2: `app-manifests/namespace.yaml`

Find and replace ALL occurrences:

- `CHANGEME-todo-app` → `thon-todo-app`
- `owner: CHANGEME` → `owner: thon`

**Lines to change:** 6, 9, 12

### File 3: `app-manifests/backend-deployment.yaml`

Find and replace ALL occurrences:

- `namespace: CHANGEME-todo-app` → `namespace: thon-todo-app`
- `owner: CHANGEME` → `owner: thon`

**Lines to change:** 8, 11, 58, 62

### File 4: `app-manifests/frontend-deployment.yaml`

Find and replace ALL occurrences:

- `namespace: CHANGEME-todo-app` → `namespace: thon-todo-app`
- `owner: CHANGEME` → `owner: thon`

**Lines to change:** 8, 11, 55, 59

---

## ✅ Step 4: Verification Checklist

Before proceeding with cluster creation, verify:

```bash
# 1. Check cluster name
grep "name: eks-" cluster-config.yaml
# Expected: name: eks-thon-cluster (with YOUR username)
# Should NOT see: name: eks-CHANGEME-cluster

# 2. Check node group name
grep "name: .*-nodes" cluster-config.yaml
# Expected: name: thon-nodes (with YOUR username)
# Should NOT see: name: CHANGEME-nodes

# 3. Check namespace
grep "name: .*-todo-app" app-manifests/namespace.yaml
# Expected: name: thon-todo-app (with YOUR username)
# Should NOT see: name: CHANGEME-todo-app

# 4. Check for any remaining CHANGEME
grep -r "CHANGEME" cluster-config.yaml app-manifests/
# Expected: No results (or only in comments)
# If you see matches, you missed some replacements!

# 5. Final verification - should return 0
grep -r "CHANGEME" cluster-config.yaml app-manifests/*.yaml | grep -v "#" | wc -l
# Expected: 0 (zero remaining CHANGEME outside of comments)
```

---

## 🚨 Common Mistakes

### ❌ Mistake 1: Forgot to replace CHANGEME

```bash
# Error when creating cluster:
# Error: cluster "eks-CHANGEME-cluster" validation failed

# Solution: Go back and replace CHANGEME with your username
```

### ❌ Mistake 2: Used full IAM username including 'eks-'

```bash
# Wrong:
name: eks-eks-thon-cluster  # DON'T do this

# Correct:
name: eks-thon-cluster  # Just the part after 'eks-'
```

### ❌ Mistake 3: Inconsistent naming

```bash
# Wrong: Using different names in different files
# cluster-config.yaml: eks-thon-cluster
# namespace.yaml: pythia-todo-app  # Different username!

# Correct: Use the SAME username everywhere
# cluster-config.yaml: eks-thon-cluster
# namespace.yaml: thon-todo-app  # Same username
```

### ❌ Mistake 4: Only replaced in some files

```bash
# Wrong: Only updated cluster-config.yaml
# You MUST update all 4 files:
# 1. cluster-config.yaml
# 2. app-manifests/namespace.yaml
# 3. app-manifests/backend-deployment.yaml
# 4. app-manifests/frontend-deployment.yaml
```

---

## 🎯 What Each File Does

### `cluster-config.yaml`

- Defines YOUR EKS cluster configuration
- Cluster name: `eks-thon-cluster`
- Node group: `thon-nodes`
- This is YOUR infrastructure

### `app-manifests/namespace.yaml`

- Creates YOUR isolated namespace
- Namespace: `thon-todo-app`
- Keeps your work separate from other participants

### `app-manifests/backend-deployment.yaml`

- Deploys backend service to YOUR namespace
- 2 replicas of backend pods
- Runs in: `thon-todo-app` namespace

### `app-manifests/frontend-deployment.yaml`

- Deploys frontend service to YOUR namespace
- 2 replicas of frontend pods
- Runs in: `thon-todo-app` namespace

---

## 🔄 What Happens Next?

After personalization:

```
You will have:
├── YOUR cluster: eks-thon-cluster
├── YOUR nodes: thon-nodes (2x t3.medium)
└── YOUR namespace: thon-todo-app
    ├── frontend (2 pods)
    └── backend (2 pods)

Other participants will have:
├── THEIR cluster: eks-pythia-cluster
├── THEIR nodes: pythia-nodes
└── THEIR namespace: pythia-todo-app
    ├── frontend (2 pods)
    └── backend (2 pods)

Everyone works independently! No conflicts! 🎉
```

---

## ✅ Ready to Proceed?

Once you've completed personalization and verification:

1. ✅ All 4 files updated with YOUR username
2. ✅ No "CHANGEME" remaining (verified)
3. ✅ Cluster name is `eks-<your-username>-cluster`
4. ✅ Namespace is `<your-username>-todo-app`

**You're ready!** Proceed to [README.md](README.md) for the full activity.

---

## 🆘 Need Help?

### Issue: "I don't know my username"

```bash
# Run this command:
aws sts get-caller-identity --query Arn --output text

# If you see: arn:aws:iam::123456789012:user/eks-thon
# Your username is: thon (the part after 'eks-')
```

### Issue: "sed command doesn't work on my Mac"

```bash
# macOS might need different syntax:
sed -i '' "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml

# Or use the backup approach:
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
```

### Issue: "I made a mistake and need to start over"

```bash
# Restore from backups if you made them:
cp cluster-config.yaml.original cluster-config.yaml
# Or re-download the original files from the repository
```

### Issue: "Verification shows remaining CHANGEME"

```bash
# Find exactly where:
grep -n "CHANGEME" cluster-config.yaml app-manifests/*.yaml | grep -v "#"

# The output shows line numbers where CHANGEME remains
# Edit those specific lines manually
```

---

**Next Step:** After successful personalization, return to [README.md](README.md) and start from "🎯 Quick Start"!
