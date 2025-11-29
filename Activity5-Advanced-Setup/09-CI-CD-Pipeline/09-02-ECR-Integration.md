# AWS ECR Integration with Jenkins

Configure Jenkins to build and push Docker images to AWS Elastic Container Registry (ECR).

---

## 🎯 Learning Objectives

- ✅ Create AWS ECR repository
- ✅ Configure Jenkins with AWS credentials
- ✅ Build Docker images in Jenkins
- ✅ Push images to ECR
- ✅ Pull images from ECR in Kubernetes

---

## ⏱️ Time Estimate

**30-35 minutes**

---

## Lab 1: Create ECR Repository

### Step 1: Create Repository

```bash
# Set variables
AWS_REGION="ap-southeast-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_NAME="todo-app"

# Create ECR repository
aws ecr create-repository \
  --repository-name $REPO_NAME \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true

# Get repository URI
ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
echo "ECR Repository: $ECR_REPO_URI"
```

### Step 2: Create Lifecycle Policy

```bash
cat <<EOF > lifecycle-policy.json
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

aws ecr put-lifecycle-policy \
  --repository-name $REPO_NAME \
  --lifecycle-policy-text file://lifecycle-policy.json \
  --region $AWS_REGION
```

---

## Lab 2: Test ECR Access

### Step 1: Login to ECR

```bash
# Get ECR login password
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REPO_URI
```

### Step 2: Test Push

```bash
# Pull test image
docker pull busybox:latest

# Tag for ECR
docker tag busybox:latest $ECR_REPO_URI:test

# Push to ECR
docker push $ECR_REPO_URI:test

# Verify
aws ecr list-images --repository-name $REPO_NAME --region $AWS_REGION
```

---

## Lab 3: Configure Jenkins Pipeline

### Step 1: Install Docker in Jenkins Agent

Update pod template to use Docker:

```yaml
# In Jenkins UI: Manage Jenkins → Configure Clouds → Kubernetes
# Add Container Template:
Name: docker
Docker image: docker:latest
Command to run: cat
Working directory: /home/jenkins/agent

# Add Volume:
Type: Host Path Volume
Host path: /var/run/docker.sock
Mount path: /var/run/docker.sock
```

### Step 2: Create Pipeline Script

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
'''
        }
    }
    
    environment {
        AWS_REGION = 'ap-southeast-1'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/todo-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/your-org/todo-app'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh '''
                        docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                        docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REPO}:latest
                    '''
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                container('docker') {
                    withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                        sh '''
                            aws ecr get-login-password --region ${AWS_REGION} | \
                              docker login --username AWS --password-stdin ${ECR_REPO}
                            docker push ${ECR_REPO}:${IMAGE_TAG}
                            docker push ${ECR_REPO}:latest
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl set image deployment/todo-app \
                          todo-app=${ECR_REPO}:${IMAGE_TAG} \
                          -n default
                        kubectl rollout status deployment/todo-app -n default
                    '''
                }
            }
        }
    }
}
```

---

## Lab 4: Create Jenkins Job

### Step 1: Create Pipeline Job

1. Go to Jenkins dashboard
2. Click "New Item"
3. Enter name: `todo-app-pipeline`
4. Select "Pipeline"
5. Click "OK"

### Step 2: Configure Pipeline

1. In "Pipeline" section:
   - Definition: "Pipeline script"
   - Script: (paste the Groovy script above)
2. Click "Save"

### Step 3: Run Pipeline

1. Click "Build Now"
2. Watch console output
3. Verify image pushed to ECR

```bash
# Verify on command line
aws ecr describe-images \
  --repository-name $REPO_NAME \
  --region $AWS_REGION
```

---

## Lab 5: Jenkinsfile in Repository

### Step 1: Create Jenkinsfile

```groovy
// Save as Jenkinsfile in repo root
pipeline {
    agent {
        kubernetes {
            yamlFile 'jenkins-pod.yaml'
        }
    }
    
    environment {
        AWS_REGION = 'ap-southeast-1'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/todo-app"
    }
    
    stages {
        stage('Build') {
            steps {
                container('docker') {
                    sh 'docker build -t ${ECR_REPO}:${GIT_COMMIT} .'
                }
            }
        }
        
        stage('Push') {
            steps {
                container('docker') {
                    script {
                        docker.withRegistry("https://${ECR_REPO}", 'ecr:ap-southeast-1:aws-credentials') {
                            docker.image("${ECR_REPO}:${GIT_COMMIT}").push()
                            docker.image("${ECR_REPO}:${GIT_COMMIT}").push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                container('kubectl') {
                    sh '''
                        kubectl set image deployment/todo-app \
                          todo-app=${ECR_REPO}:${GIT_COMMIT}
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### Step 2: Create jenkins-pod.yaml

```yaml
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: docker
    image: docker:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
```

### Step 3: Configure Pipeline from SCM

1. Edit pipeline job
2. Change Definition to "Pipeline script from SCM"
3. SCM: Git
4. Repository URL: your-repo-url
5. Script Path: `Jenkinsfile`
6. Save

---

## 💡 Best Practices

```yaml
Image Tagging Strategy:
├── Use Git commit SHA for traceability
├── Tag with build number
├── Always tag 'latest' for easy rollback
└── Use semantic versioning for releases

Example:
- ${ECR_REPO}:${GIT_COMMIT}
- ${ECR_REPO}:build-${BUILD_NUMBER}
- ${ECR_REPO}:v1.2.3
- ${ECR_REPO}:latest
```

---

## ✅ Knowledge Check

- [ ] Create and configure ECR repository
- [ ] Build Docker images in Jenkins
- [ ] Push images to ECR
- [ ] Deploy from ECR to Kubernetes

---

## 🚀 Next

**Continue to:** [09-03-Pipeline-Configuration.md](09-03-Pipeline-Configuration.md)

---

**Excellent!** Your CI/CD pipeline is taking shape! 🐳

