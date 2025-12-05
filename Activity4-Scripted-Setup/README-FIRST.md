# 🎯 START HERE - Activity 4 Setup

## ✨ What's New?

Activity 4 has been updated to support **7 individual participants**, each with their own cluster!

---

## 🚀 Quick Start (3 Steps)

### Step 1: Find Your Username

Check your IAM username:
```bash
aws sts get-caller-identity --query Arn --output text
```

Example output: `arn:aws:iam::123456789012:user/eks-thon`

Your username is: **thon** (the part after `eks-`)

### Step 2: Personalize Your Files

```bash
# Set your username
export MY_USERNAME="thon"  # CHANGE THIS to YOUR username!

# Navigate to Activity 4
cd /path/to/EKS-Training/Activity4-Scripted-Setup

# Replace CHANGEME with your username
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml
sed -i.bak "s/CHANGEME/$MY_USERNAME/g" app-manifests/*.yaml

# Verify it worked
./validate-personalization.sh
```

Expected output:
```
✅ PASS: cluster-config.yaml
✅ PASS: app-manifests/namespace.yaml
✅ PASS: app-manifests/backend-deployment.yaml
✅ PASS: app-manifests/frontend-deployment.yaml
🎉 SUCCESS! All validations passed!
```

### Step 3: Start the Activity

Now proceed to [README.md](README.md) and follow the main activity!

---

## 📚 Important Files

| File | Purpose | When to Use |
|------|---------|-------------|
| **README-FIRST.md** | This file - quick start | Read first |
| **00-PERSONALIZATION-GUIDE.md** | Detailed setup guide | If you need help |
| **validate-personalization.sh** | Check your setup | After personalizing |
| **QUICK-REFERENCE-CARD.md** | Command cheatsheet | During activity |
| **README.md** | Main activity guide | After personalizing |

---

## 👥 The 7 Participants

Each participant has unique resources:

| # | Username | Cluster | Namespace |
|---|----------|---------|-----------|
| 1 | thon | eks-thon-cluster | thon-todo-app |
| 2 | pythia | eks-pythia-cluster | pythia-todo-app |
| 3 | cronus | eks-cronus-cluster | cronus-todo-app |
| 4 | rhea | eks-rhea-cluster | rhea-todo-app |
| 5 | atlas | eks-atlas-cluster | atlas-todo-app |
| 6 | helios | eks-helios-cluster | helios-todo-app |
| 7 | selene | eks-selene-cluster | selene-todo-app |

**You work independently - no conflicts!** 🎉

---

## ⚠️ Don't Skip Personalization!

Without personalization:
- ❌ Your cluster creation will fail
- ❌ You'll conflict with other participants
- ❌ Commands in guides won't work

With personalization:
- ✅ Everything works smoothly
- ✅ Complete isolation from others
- ✅ Clear ownership of resources

---

## 🆘 Need Help?

### Issue: "I don't know my username"
```bash
aws sts get-caller-identity --query Arn --output text
# Look for: arn:aws:iam::123456789012:user/eks-YOURNAME
# Your username is the part after "eks-"
```

### Issue: "sed command doesn't work"
Try with different syntax:
```bash
# macOS alternative
sed -i '' "s/CHANGEME/$MY_USERNAME/g" cluster-config.yaml

# Or edit files manually
# See 00-PERSONALIZATION-GUIDE.md for manual instructions
```

### Issue: "Validation fails"
```bash
# See what's still wrong
grep -rn "CHANGEME" cluster-config.yaml app-manifests/ | grep -v "#"

# Each line shows: filename:lineNumber:content
# Edit those specific lines to replace CHANGEME with your username
```

---

## ✅ Ready?

Once you see **"🎉 SUCCESS!"** from `validate-personalization.sh`:

👉 **Go to [README.md](README.md) and start Activity 4!**

---

## 📞 For Instructors

See **[PARTICIPANT-RESOURCES.md](PARTICIPANT-RESOURCES.md)** for:
- Tracking all 7 participants
- Cost monitoring
- Cluster verification
- Cleanup validation
- Issue management

---

**Time to personalize:** ~2 minutes  
**Time for activity:** ~2-2.5 hours  
**Cost per participant:** ~$3.15/day

💡 **Tip:** Print [QUICK-REFERENCE-CARD.md](QUICK-REFERENCE-CARD.md) before starting!

