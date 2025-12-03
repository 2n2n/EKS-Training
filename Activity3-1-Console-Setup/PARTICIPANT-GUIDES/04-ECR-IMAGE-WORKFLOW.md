# Activity 4: ECR Image Workflow

**For:** Workshop Participants  
**Time:** 30 minutes  
**Prerequisites:** Docker installed, completed previous activities

Learn how to build Docker images, push them to the shared ECR repository, and use them in your deployments.

---

## 🎯 What You'll Learn

- Authenticate Docker with Amazon ECR
- Build Docker images locally
- Tag images with proper naming conventions
- Push images to the shared ECR repository
- Pull and verify images
- Use ECR images in Kubernetes deployments

---

## Understanding ECR

**What is Amazon ECR?**
- Elastic Container Registry = AWS Docker image storage
- Like Docker Hub, but private and AWS-integrated
- Stores your application container images

**Shared Repository Setup:**
```
ECR Repository: eks-workshop-apps
│
├── charles-webapp-v1    (Charles's app)
├── charles-webapp-v2    (Charles's updated app)
├── joshua-api-v1        (Joshua's app)
├── robert-frontend-v1   (Robert's app)
└── ... (everyone's images)
```

**Tagging Convention:**
```
Format: <your-name>-<app-name>-<version>

Examples:
✅ charles-webapp-v1
✅ charles-api-latest
✅ joshua-frontend-v2

❌ webapp (no username!)
❌ v1 (no app name!)
```

---

## Step 1: Get ECR Repository Information

### From Workshop Admin

The admin will provide:
```
Repository Name: eks-workshop-apps
Region: ap-southeast-1
URI: <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps
```

### Get URI Yourself

```bash
# List repositories
aws ecr describe-repositories --region ap-southeast-1

# Get specific repository URI
aws ecr describe-repositories \
    --repository-names eks-workshop-apps \
    --region ap-southeast-1 \
    --query 'repositories[0].repositoryUri' \
    --output text
```

**Save this URI!** You'll use it repeatedly.

---

## Step 2: Authenticate Docker with ECR

### Get Login Command

```bash
# Authenticate Docker with ECR
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
```

**Expected output:**
```
Login Succeeded
```

### Authentication Notes

- Token is valid for **12 hours**
- Re-run the command if you get authentication errors
- Works for all repositories in that AWS account

---

## Step 3: Build a Docker Image

### Create a Simple Application

Create a project directory:

```bash
mkdir ~/my-workshop-app
cd ~/my-workshop-app
```

### Create Application Files

**Create index.html:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Hello from Charles!</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        h1 { color: #2196F3; }
    </style>
</head>
<body>
    <h1>Hello from Charles's App!</h1>
    <p>Running on Kubernetes in EKS</p>
    <p>Version: v1</p>
</body>
</html>
```

**Create Dockerfile:**
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Build the Image

```bash
# Build with local tag first
docker build -t charles-webapp:v1 .

# Verify image was created
docker images | grep charles-webapp
```

**Expected output:**
```
charles-webapp   v1   abc123def   5 seconds ago   23MB
```

### Test Locally (Optional)

```bash
# Run container locally
docker run -d -p 8080:80 --name test-app charles-webapp:v1

# Test in browser: http://localhost:8080
# Or with curl:
curl http://localhost:8080

# Stop and remove when done
docker stop test-app && docker rm test-app
```

---

## Step 4: Tag Image for ECR

### Tag with ECR Repository URI

```bash
# Set your ECR URI (get from Step 1)
ECR_URI="<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps"

# Tag with naming convention
docker tag charles-webapp:v1 $ECR_URI:charles-webapp-v1

# Verify tag
docker images | grep charles-webapp
```

**You should see two entries:**
```
charles-webapp                v1            abc123def
<ecr-uri>/eks-workshop-apps   charles-webapp-v1   abc123def
```

---

## Step 5: Push Image to ECR

### Push the Image

```bash
# Push to ECR
docker push $ECR_URI:charles-webapp-v1
```

**Expected output:**
```
The push refers to repository [<account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps]
abc123: Pushed
def456: Pushed
charles-webapp-v1: digest: sha256:xxx size: 1234
```

### Verify in AWS Console

1. Go to **ECR Console**
2. Click on **eks-workshop-apps**
3. You should see your image: `charles-webapp-v1`

### Verify via CLI

```bash
# List images in repository
aws ecr list-images \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1

# Get image details
aws ecr describe-images \
    --repository-name eks-workshop-apps \
    --image-ids imageTag=charles-webapp-v1 \
    --region ap-southeast-1
```

---

## Step 6: Pull Image (Test)

### Pull the Image

```bash
# Pull your image (to verify it works)
docker pull $ECR_URI:charles-webapp-v1

# Run to verify
docker run -d -p 8080:80 $ECR_URI:charles-webapp-v1
curl http://localhost:8080
docker stop $(docker ps -q)
```

### Pull Someone Else's Image (If Available)

```bash
# Pull another participant's image
docker pull $ECR_URI:joshua-webapp-v1
```

---

## Step 7: Use ECR Image in Kubernetes

### Create Deployment Using Your Image

```yaml
# Save as charles-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: charles-webapp
  namespace: charles-workspace
  labels:
    app: charles-webapp
    owner: charles
spec:
  replicas: 2
  selector:
    matchLabels:
      app: charles-webapp
  template:
    metadata:
      labels:
        app: charles-webapp
        owner: charles
    spec:
      containers:
      - name: webapp
        image: <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/eks-workshop-apps:charles-webapp-v1
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: charles-webapp-svc
  namespace: charles-workspace
spec:
  type: NodePort
  selector:
    app: charles-webapp
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30081
```

**Replace `<account-id>` with actual account ID!**

### Deploy to Kubernetes

```bash
# Apply deployment
kubectl apply -f charles-deployment.yaml

# Watch pods start
kubectl get pods -n charles-workspace -w

# Check deployment
kubectl get deployment charles-webapp -n charles-workspace
```

### Verify Pods Are Using ECR Image

```bash
# Describe pod to see image
kubectl describe pod -l app=charles-webapp -n charles-workspace | grep Image
```

---

## Step 8: Update Image (Push New Version)

### Update Your Application

```bash
# Edit index.html
sed -i 's/Version: v1/Version: v2/' index.html

# Or manually edit to change content
```

### Build, Tag, Push v2

```bash
# Build new version
docker build -t charles-webapp:v2 .

# Tag for ECR
docker tag charles-webapp:v2 $ECR_URI:charles-webapp-v2

# Push
docker push $ECR_URI:charles-webapp-v2
```

### Update Kubernetes Deployment

```bash
# Update image in deployment
kubectl set image deployment/charles-webapp \
    webapp=$ECR_URI:charles-webapp-v2 \
    -n charles-workspace

# Watch rollout
kubectl rollout status deployment/charles-webapp -n charles-workspace
```

---

## Step 9: List and Manage Images

### List All Images

```bash
# List all images in repository
aws ecr list-images \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1 \
    --output table
```

### View Your Images Only

```bash
# Filter images by tag prefix
aws ecr list-images \
    --repository-name eks-workshop-apps \
    --region ap-southeast-1 \
    --query "imageIds[?contains(imageTag, 'charles')]"
```

### Delete Your Old Images (Optional)

```bash
# Delete specific image (only YOUR images!)
aws ecr batch-delete-image \
    --repository-name eks-workshop-apps \
    --image-ids imageTag=charles-webapp-v1 \
    --region ap-southeast-1
```

⚠️ **Only delete YOUR images!**

---

## 🚨 Troubleshooting

### Issue: "no basic auth credentials"

**Error:**
```
Error response from daemon: no basic auth credentials
```

**Solution:**
```bash
# Re-authenticate
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin \
    <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com
```

---

### Issue: "denied: User is not authorized"

**Error:**
```
denied: User: arn:aws:iam::xxx:user/eks-charles is not authorized
```

**Solution:**
- Check with workshop admin
- Verify your IAM user has ECR permissions
- Try re-authenticating

---

### Issue: "ImagePullBackOff" in Kubernetes

**Error in pod:**
```
Events:
  Failed to pull image "xxx": rpc error: ImagePullBackOff
```

**Solutions:**
```bash
# 1. Verify image exists
aws ecr list-images --repository-name eks-workshop-apps --region ap-southeast-1

# 2. Check image tag is correct (case-sensitive!)
kubectl describe pod <pod-name> -n <namespace> | grep Image

# 3. EKS nodes have ECR access by default via node role
# If still failing, check node role has AmazonEC2ContainerRegistryReadOnly policy
```

---

## ✅ Validation Checklist

- [ ] Authenticated Docker with ECR
- [ ] Built a Docker image locally
- [ ] Tagged image with naming convention
- [ ] Pushed image to ECR
- [ ] Verified image in ECR console
- [ ] Deployed using ECR image in Kubernetes
- [ ] Pods successfully pulled and ran the image

---

## 📋 Quick Commands Reference

```bash
# AUTHENTICATE
aws ecr get-login-password --region ap-southeast-1 | \
    docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

# BUILD
docker build -t <your-name>-<app>:<version> .

# TAG
docker tag <local-image> <ecr-uri>:<your-name>-<app>-<version>

# PUSH
docker push <ecr-uri>:<your-name>-<app>-<version>

# PULL
docker pull <ecr-uri>:<your-name>-<app>-<version>

# LIST images
aws ecr list-images --repository-name eks-workshop-apps --region ap-southeast-1

# DESCRIBE image
aws ecr describe-images --repository-name eks-workshop-apps --image-ids imageTag=<tag> --region ap-southeast-1

# DELETE image (only yours!)
aws ecr batch-delete-image --repository-name eks-workshop-apps --image-ids imageTag=<your-tag> --region ap-southeast-1
```

---

## 🎓 What You Learned

- ✅ How to authenticate with ECR
- ✅ How to build and tag Docker images
- ✅ Image naming conventions for shared repos
- ✅ How to push/pull images from ECR
- ✅ How to use ECR images in Kubernetes
- ✅ How to update deployments with new images

---

## 🚀 Next Activity

Now let's deploy a complete application!

**Next:** [05-DEPLOY-APPLICATIONS.md](05-DEPLOY-APPLICATIONS.md) - Deploy applications with deployments, services, and more

---

## 📚 Additional Resources

- [Amazon ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- [Docker Build Documentation](https://docs.docker.com/engine/reference/commandline/build/)
- [Kubernetes Container Images](https://kubernetes.io/docs/concepts/containers/images/)

