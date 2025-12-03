# Root Setup 05: ECR Registry Setup

**For:** Workshop Administrator (Root Account)  
**Time:** 10 minutes  
**Cost Impact:** $0.10/GB/month for stored images (~$0.50 for workshop)

Create a shared Amazon ECR repository where all participants can push and pull Docker images.

---

## 🎯 What You'll Create

- 1× ECR Repository (shared by all participants)
- Lifecycle policy to manage image retention
- Access permissions for all workshop participants

---

## 📋 Prerequisites

- [ ] AWS CLI configured
- [ ] Region: **ap-southeast-1**
- [ ] ECR permissions: `ecr:CreateRepository`, `ecr:PutLifecyclePolicy`

---

## Understanding Amazon ECR

**What is ECR?**

- Elastic Container Registry = Docker image storage in AWS
- Like Docker Hub, but private and integrated with AWS
- Highly available and scalable

**Why Shared Repository?**

- Simpler permission management
- Lower cost (1 repo vs 7 repos)
- Easy to see all workshop images
- Teaches naming discipline with tags

---

## Step 1: Create ECR Repository

### Via AWS Console

1. Go to **ECR Console**: https://console.aws.amazon.com/ecr/
2. Ensure you're in **ap-southeast-1** region
3. Click **Get Started** (if first time) or **Create repository**

**Settings:**

```
Visibility settings: ○ Private
Repository name: eks-workshop-apps
```

**Tag immutability:**

```
○ Disabled (allows overwriting tags)
```

**Why disabled?**

- Participants can update their images
- Can push same tag (e.g., myapp:v1) multiple times
- More flexible for learning

**Image scan settings:**

```
☐ Scan on push (optional - adds time)
```

**Encryption settings:**

```
● AES-256 (default, no extra cost)
```

Click **Create repository**

### Via AWS CLI

```bash
# Create repository
aws ecr create-repository \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1 \
    --image-scanning-configuration scanOnPush=false \
    --encryption-configuration encryptionType=AES256 \
    --tags Key=Project,Value=EKS-Workshop Key=Environment,Value=Training

# Get repository details
aws ecr describe-repositories \
    --repository-names eks-workshop-apps \
    --region ap-southeast-1
```

---

## Step 2: Get Repository URI

The URI is needed by participants to push/pull images.

### Via AWS Console

1. In ECR Console, click on **eks-workshop-apps**
2. Copy the **URI** shown at top:

```
<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps
```

### Via AWS CLI

```bash
# Get repository URI
aws ecr describe-repositories \
    --repository-names eks-workshop-apps \
    --region ap-southeast-1 \
    --query 'repositories[0].repositoryUri' \
    --output text

# Example output:
# 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps
```

**Save this URI!** Participants need it to push images.

---

## Step 3: Set Lifecycle Policy (Optional but Recommended)

Prevent image accumulation and control costs.

### Create Lifecycle Policy

This policy automatically deletes old images to save storage costs.

**Via AWS Console:**

1. In ECR Console, select **eks-workshop-apps**
2. Click **Lifecycle policy** in left panel
3. Click **Create rule**

**Rule 1 - Keep recent images:**

```
Rule priority: 1
Rule description: Keep last 10 images per participant
Image status: Any
Match criteria: Since image pushed
Count type: Image count more than
Count number: 10
```

Click **Save**

**Via AWS CLI:**

```bash
# Create lifecycle policy file
cat > lifecycle-policy.json << 'EOF'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

# Apply lifecycle policy
aws ecr put-lifecycle-policy \
    --repository-name eks-workshop-apps \
    --lifecycle-policy-text file://lifecycle-policy.json \
    --region ap-southeast-1
```

**What this does:**

- Keeps only the 10 most recent images
- Automatically deletes older images
- Saves storage costs
- Good for learning environment

---

## Step 4: Configure Repository Permissions

Grant participants access to push/pull images.

### Option A: Using IAM Policy (Already Done!)

If you followed the setup-participants.sh script, participants already have ECR permissions via the EKSWorkshopPolicy:

- `ecr:*` on all resources

**Verify participants have access:**

```bash
# Check if EKSWorkshopPolicy includes ECR permissions
aws iam get-policy-version \
    --policy-arn arn:aws:iam::<account-id>:policy/EKSWorkshopPolicy \
    --version-id v1 \
    --query 'PolicyVersion.Document.Statement[?contains(Sid, `ECR`)]'
```

### Option B: Repository Policy (More Restrictive - Optional)

For finer control, you can add a repository-specific policy:

```bash
# Create repository policy
cat > repo-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowWorkshopParticipants",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::<account-id>:user/eks-charles",
          "arn:aws:iam::<account-id>:user/eks-joshua",
          "arn:aws:iam::<account-id>:user/eks-robert",
          "arn:aws:iam::<account-id>:user/eks-sharmaine",
          "arn:aws:iam::<account-id>:user/eks-daniel",
          "arn:aws:iam::<account-id>:user/eks-jett",
          "arn:aws:iam::<account-id>:user/eks-thon"
        ]
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:ListImages"
      ]
    }
  ]
}
EOF

# Apply repository policy
aws ecr set-repository-policy \
    --repository-name eks-workshop-apps \
    --policy-text file://repo-policy.json \
    --region ap-southeast-1
```

---

## Step 5: Document Image Tagging Convention

Create guidelines for participants to name their images.

**Tagging Convention:**

```
Format: <username>-<appname>-<version>

Examples:
✅ charles-webapp-v1
✅ joshua-api-v2
✅ robert-frontend-v3
✅ sharmaine-backend-latest
```

**Full Image Name:**

```
<ecr-uri>:<username>-<appname>-<version>

Example:
123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps:charles-webapp-v1
```

**Why This Matters:**

- Prevents naming conflicts
- Easy to identify image owners
- Clean organization
- Simplifies cleanup

---

## ✅ Validation

Verify repository is ready for participants.

### Via AWS Console

1. ECR Console should show:

```
Repository name: eks-workshop-apps
URI: <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps
Images: 0 (none yet - that's correct!)
```

2. Click on repository:

```
Repository details:
├── Created: (timestamp)
├── Image tag mutability: MUTABLE
├── Scan on push: DISABLED
├── Encryption: AES-256
└── Lifecycle policy: (configured if you set one)
```

### Via AWS CLI

```bash
# List repositories
aws ecr describe-repositories --region ap-southeast-1 \
    --query 'repositories[].repositoryName'

# Should include: eks-workshop-apps

# Get repository details
aws ecr describe-repositories \
    --repository-names eks-workshop-apps \
    --region ap-southeast-1 \
    --output json

# List images (should be empty initially)
aws ecr list-images \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1

# Expected output:
# {
#     "imageIds": []
# }
```

### Test Authentication (From Your Machine)

```bash
# Get Docker login command
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

# Expected output:
# Login Succeeded
```

---

## 📝 Information for Participants

Provide this information to all participants:

```
ECR Repository Information
==========================

Repository Name: eks-workshop-apps
Region: ap-southeast-1
URI: <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps

Image Naming Convention:
Format: <your-name>-<app-name>-<version>
Examples: charles-webapp-v1, joshua-api-v2

Authentication Command:
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

Push Example:
1. Build: docker build -t myapp .
2. Tag: docker tag myapp:latest <ecr-uri>:charles-webapp-v1
3. Push: docker push <ecr-uri>:charles-webapp-v1

Pull Example:
docker pull <ecr-uri>:charles-webapp-v1
```

---

## 🚨 Troubleshooting

### Issue: Can't Create Repository

**Error:** "The maximum number of repositories has been reached"

**Solution:**

```bash
# Check ECR limit
aws service-quotas get-service-quota \
    --service-code ecr \
    --quota-code L-4F2D01EA \
    --region ap-southeast-1

# Default limit: 10,000 repositories per region
# If you're hitting this, delete unused repositories:
aws ecr delete-repository \
    --repository-name <unused-repo> \
    --force \
    --region ap-southeast-1
```

---

### Issue: Participant Can't Push Images

**Error:** "denied: User is not authorized"

**Check 1: IAM Permissions**

```bash
# Verify participant has ECR permissions
aws iam get-user-policy \
    --user-name eks-charles \
    --policy-name EKSWorkshopPolicy

# Should show ecr:* actions
```

**Check 2: Authentication**

```bash
# Participant should run:
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

# Token expires after 12 hours - need to re-authenticate
```

**Check 3: Repository Policy**

```bash
# Check repository policy
aws ecr get-repository-policy \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1

# Verify participant's ARN is included
```

---

## 💰 Cost Management

### ECR Pricing

```
Storage: $0.10/GB/month
Data Transfer Out: $0.09/GB (after 1GB free)

Example Workshop Costs:
├── 7 participants × 3 images each = 21 images
├── Average image size: 200MB
├── Total storage: 4.2GB
└── Monthly cost: $0.42

For 4-hour workshop:
└── Cost: ~$0.01 (negligible!)
```

### Monitor Storage

```bash
# Check repository size (need to list all images)
aws ecr list-images \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1

# View image details including size
aws ecr describe-images \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1
```

---

## 🎓 What You've Accomplished

```
✅ Created shared ECR repository
✅ Configured lifecycle policy
✅ Set up participant access
✅ Documented naming conventions
✅ Ready for Docker image push/pull

Participants can now:
├── Build Docker images locally
├── Push images to shared registry
├── Pull images for deployments
├── Share images with team
└── Learn Docker & ECR workflows
```

---

## 🚀 Next Steps

ECR is ready! Continue to:

**Next:** [06-PARTICIPANT-ACCESS.md](06-PARTICIPANT-ACCESS.md) - Grant cluster access to participants

This is the final setup step! After this, participants can start using the cluster.

---

## 📚 Additional Resources

- [Amazon ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [ECR Lifecycle Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
- [ECR Repository Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html)
- [Docker CLI with ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html)
