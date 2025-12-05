# Participant Resource Reference

This document lists all participant usernames and their corresponding AWS resources for Activity 4.

---

## 📋 Participant List

| # | IAM Username | Short Name | Cluster Name | Node Group | Namespace | Status |
|---|--------------|------------|--------------|------------|-----------|--------|
| 1 | eks-thon | thon | eks-thon-cluster | thon-nodes | thon-todo-app | ⬜ Not Started |
| 2 | eks-pythia | pythia | eks-pythia-cluster | pythia-nodes | pythia-todo-app | ⬜ Not Started |
| 3 | eks-cronus | cronus | eks-cronus-cluster | cronus-nodes | cronus-todo-app | ⬜ Not Started |
| 4 | eks-rhea | rhea | eks-rhea-cluster | rhea-nodes | rhea-todo-app | ⬜ Not Started |
| 5 | eks-atlas | atlas | eks-atlas-cluster | atlas-nodes | atlas-todo-app | ⬜ Not Started |
| 6 | eks-helios | helios | eks-helios-cluster | helios-nodes | helios-todo-app | ⬜ Not Started |
| 7 | eks-selene | selene | eks-selene-cluster | selene-nodes | selene-todo-app | ⬜ Not Started |

**Status Legend:**
- ⬜ Not Started
- 🟡 In Progress
- ✅ Completed
- ❌ Issues

---

## 🔍 Verification Commands

### Check All Clusters

```bash
# List all EKS clusters in the region
aws eks list-clusters --region ap-southeast-1

# Expected output (when all participants create clusters):
# {
#     "clusters": [
#         "eks-thon-cluster",
#         "eks-pythia-cluster",
#         "eks-cronus-cluster",
#         "eks-rhea-cluster",
#         "eks-atlas-cluster",
#         "eks-helios-cluster",
#         "eks-selene-cluster"
#     ]
# }
```

### Check Specific Participant's Cluster

```bash
# Replace 'thon' with the participant's short name
PARTICIPANT="thon"

# Check cluster status
aws eks describe-cluster \
  --name eks-${PARTICIPANT}-cluster \
  --region ap-southeast-1 \
  --query 'cluster.status' \
  --output text

# Check node group
aws eks describe-nodegroup \
  --cluster-name eks-${PARTICIPANT}-cluster \
  --nodegroup-name ${PARTICIPANT}-nodes \
  --region ap-southeast-1 \
  --query 'nodegroup.status' \
  --output text
```

### Check All Participant Clusters at Once

```bash
# Create a quick status check script
for participant in thon pythia cronus rhea atlas helios selene; do
  echo "Checking $participant..."
  CLUSTER_STATUS=$(aws eks describe-cluster \
    --name eks-${participant}-cluster \
    --region ap-southeast-1 \
    --query 'cluster.status' \
    --output text 2>/dev/null || echo "NOT_FOUND")
  echo "  Cluster: $CLUSTER_STATUS"
done
```

---

## 💰 Cost Tracking

### Per Participant (Daily)

```
Each participant's cluster costs:
├── EKS Control Plane: $0.10/hour = $2.40/day
├── 2x t3.medium Spot: $0.025/hour = $0.60/day
├── 2x 20GB gp3 EBS: $0.11/day
└── Total: ~$3.15/day per participant
```

### All 7 Participants (Daily)

```
Total if all running:
└── 7 participants × $3.15/day = ~$22.05/day
```

### CloudWatch Cost Tracking

```bash
# Get cost by participant (if cost allocation tags are enabled)
aws ce get-cost-and-usage \
  --time-period Start=2024-12-01,End=2024-12-05 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Owner \
  --filter file://filter.json

# filter.json:
{
  "Tags": {
    "Key": "Project",
    "Values": ["EKS-Training"]
  }
}
```

---

## 🧹 Cleanup Verification

### Check if Participant Cleaned Up

```bash
# Replace 'thon' with participant name
PARTICIPANT="thon"

# Check if cluster exists
aws eks describe-cluster \
  --name eks-${PARTICIPANT}-cluster \
  --region ap-southeast-1 2>&1 | grep -q "ResourceNotFoundException"

if [ $? -eq 0 ]; then
  echo "✅ $PARTICIPANT has cleaned up their cluster"
else
  echo "❌ $PARTICIPANT's cluster still exists"
fi
```

### Check All Participants' Cleanup

```bash
echo "Cleanup Status:"
echo "==============="

for participant in thon pythia cronus rhea atlas helios selene; do
  aws eks describe-cluster \
    --name eks-${participant}-cluster \
    --region ap-southeast-1 &>/dev/null
  
  if [ $? -ne 0 ]; then
    echo "✅ $participant - Cleaned up"
  else
    echo "❌ $participant - Still running"
  fi
done
```

### Force Cleanup (If Needed)

```bash
# If a participant forgot to clean up, instructor can run:
PARTICIPANT="thon"  # Replace with participant name

# Delete the cluster (will also delete node groups)
eksctl delete cluster \
  --name eks-${PARTICIPANT}-cluster \
  --region ap-southeast-1

# Or delete specific resources
aws eks delete-nodegroup \
  --cluster-name eks-${PARTICIPANT}-cluster \
  --nodegroup-name ${PARTICIPANT}-nodes \
  --region ap-southeast-1

aws eks delete-cluster \
  --name eks-${PARTICIPANT}-cluster \
  --region ap-southeast-1
```

---

## 📊 Monitoring Dashboard

### Cluster Health Check

```bash
#!/bin/bash
# cluster-health-check.sh

echo "Activity 4 - Participant Cluster Status"
echo "========================================"
echo ""

PARTICIPANTS=("thon" "pythia" "cronus" "rhea" "atlas" "helios" "selene")

for participant in "${PARTICIPANTS[@]}"; do
  echo "Participant: $participant"
  echo "----------------"
  
  # Check cluster
  CLUSTER_STATUS=$(aws eks describe-cluster \
    --name eks-${participant}-cluster \
    --region ap-southeast-1\
    --query 'cluster.status' \
    --output text 2>/dev/null || echo "NOT_FOUND")
  
  if [ "$CLUSTER_STATUS" == "NOT_FOUND" ]; then
    echo "  Status: ⬜ Not created yet"
  elif [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
    # Get node count
    NODE_COUNT=$(aws eks describe-nodegroup \
      --cluster-name eks-${participant}-cluster \
      --nodegroup-name ${participant}-nodes \
      --region ap-southeast-1 \
      --query 'nodegroup.scalingConfig.desiredSize' \
      --output text 2>/dev/null || echo "0")
    
    echo "  Status: ✅ Active"
    echo "  Nodes: $NODE_COUNT"
    
    # Get creation time
    CREATED=$(aws eks describe-cluster \
      --name eks-${participant}-cluster \
      --region ap-southeast-1 \
      --query 'cluster.createdAt' \
      --output text)
    echo "  Created: $CREATED"
  else
    echo "  Status: 🟡 $CLUSTER_STATUS"
  fi
  
  echo ""
done

echo "========================================"
echo "Summary:"
TOTAL_CLUSTERS=$(aws eks list-clusters --region ap-southeast-1 --query 'length(clusters)' --output text)
echo "Total clusters: $TOTAL_CLUSTERS"
```

---

## 🚨 Common Issues by Participant

### Issue Tracking Template

```markdown
## Participant: [NAME]

### Issue:
[Description of the issue]

### Resolution:
[How it was resolved]

### Prevention:
[How to prevent this in the future]
```

---

## 📝 Activity Completion Checklist

Use this to track participant progress:

### Participant 1: thon
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

### Participant 2: pythia
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

### Participant 3: cronus
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

### Participant 4: rhea
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

### Participant 5: atlas
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

### Participant 6: helios
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

### Participant 7: selene
- [ ] Files personalized
- [ ] Cluster created
- [ ] Pods deployed
- [ ] Application tested
- [ ] Cluster deleted
- [ ] Verified cleanup

---

## 🎯 Success Metrics

Track these metrics for the activity:

| Metric | Target | Actual |
|--------|--------|--------|
| Participants completed | 7/7 | ___/7 |
| Average completion time | 2-2.5 hours | ___ hours |
| Clusters properly cleaned up | 7/7 | ___/7 |
| Total AWS cost | < $25 | $____ |
| Issues encountered | < 3 | ___ |
| Satisfaction score | > 4/5 | ___/5 |

---

## 📞 Emergency Contacts

**Instructor:** [Name]  
**AWS Support:** [Support plan details]  
**Billing Alerts:** [Alert contact]

---

## 🔐 Security Notes

### IAM User Permissions

Each participant should have:
- ✅ EKS full access (their own clusters only)
- ✅ EC2 access (for nodes)
- ✅ VPC access (for networking)
- ✅ IAM limited access (for roles)
- ❌ No access to other participants' resources
- ❌ No access to production accounts

### Resource Tags

All resources should be tagged:
```yaml
Project: EKS-Training
Activity: Activity4
Owner: [participant-username]
Environment: Training
AutoDelete: true
```

### Cost Protection

- [ ] Billing alerts configured for each participant
- [ ] Service Control Policies (SCPs) limit expensive resources
- [ ] Auto-shutdown scheduled if training ends
- [ ] Regular cost monitoring dashboard

---

## 📚 Additional Resources

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [eksctl Documentation](https://eksctl.io/)
- [kubectl Cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Last Updated:** [Date]  
**Activity Duration:** [Start Date] to [End Date]  
**Region:** ap-southeast-1 (Singapore)

