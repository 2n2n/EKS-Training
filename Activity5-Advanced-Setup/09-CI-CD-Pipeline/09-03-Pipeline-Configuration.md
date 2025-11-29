# Complete CI/CD Pipeline Configuration

Configure a complete CI/CD pipeline with Git, Jenkins, Docker, ECR, and Kubernetes.

---

## 🎯 Learning Objectives

- ✅ Create complete Jenkinsfile
- ✅ Configure Git webhooks
- ✅ Implement testing in pipeline
- ✅ Add deployment stages
- ✅ Configure notifications

---

## ⏱️ Time Estimate

**40-45 minutes**

---

## Complete Pipeline Flow

```
Git Push → Webhook → Jenkins → Build → Test → Build Image → 
Push to ECR → Deploy to K8s → Verify → Notify
```

---

## Lab 1: Complete Jenkinsfile

### Create Production-Ready Jenkinsfile

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: node
    image: node:18
    command: [cat]
    tty: true
  - name: docker
    image: docker:latest
    command: [cat]
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: kubectl
    image: bitnami/kubectl:latest
    command: [cat]
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
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/todo-app"
        IMAGE_TAG = "${GIT_COMMIT.take(8)}"
        DEPLOY_ENV = 'production'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_MSG = sh(
                        script: 'git log -1 --pretty=%B',
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                container('node') {
                    sh '''
                        npm install
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                container('node') {
                    sh '''
                        npm test
                        npm run lint
                    '''
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh '''
                        docker build \
                          --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
                          --build-arg VCS_REF=${GIT_COMMIT} \
                          --build-arg BUILD_NUMBER=${BUILD_NUMBER} \
                          -t ${ECR_REPO}:${IMAGE_TAG} \
                          -t ${ECR_REPO}:build-${BUILD_NUMBER} \
                          -t ${ECR_REPO}:latest \
                          .
                    '''
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                container('docker') {
                    sh '''
                        # Install trivy
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
                        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
                        apt-get update && apt-get install -y trivy
                        
                        # Scan image
                        trivy image --severity HIGH,CRITICAL ${ECR_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                container('docker') {
                    withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                        sh '''
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | \
                              docker login --username AWS --password-stdin ${ECR_REPO}
                            
                            # Push all tags
                            docker push ${ECR_REPO}:${IMAGE_TAG}
                            docker push ${ECR_REPO}:build-${BUILD_NUMBER}
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
                        # Update deployment image
                        kubectl set image deployment/todo-app \
                          todo-app=${ECR_REPO}:${IMAGE_TAG} \
                          -n ${DEPLOY_ENV}
                        
                        # Annotate deployment with build info
                        kubectl annotate deployment/todo-app \
                          kubernetes.io/change-cause="Build ${BUILD_NUMBER}: ${GIT_COMMIT_MSG}" \
                          -n ${DEPLOY_ENV} \
                          --overwrite
                        
                        # Wait for rollout
                        kubectl rollout status deployment/todo-app \
                          -n ${DEPLOY_ENV} \
                          --timeout=5m
                    '''
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                container('kubectl') {
                    sh '''
                        # Check if pods are running
                        kubectl get pods -n ${DEPLOY_ENV} -l app=todo-app
                        
                        # Verify new image is deployed
                        kubectl get deployment todo-app -n ${DEPLOY_ENV} \
                          -o jsonpath='{.spec.template.spec.containers[0].image}'
                    '''
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                container('node') {
                    sh '''
                        # Get service endpoint
                        SERVICE_URL=$(kubectl get service todo-app \
                          -n ${DEPLOY_ENV} \
                          -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                        
                        # Wait for endpoint
                        sleep 30
                        
                        # Health check
                        curl -f http://${SERVICE_URL}/health || exit 1
                        
                        echo "Smoke tests passed!"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
            // Add Slack/email notification here
        }
        failure {
            echo 'Pipeline failed!'
            // Add Slack/email notification here
            
            // Rollback on failure
            container('kubectl') {
                sh '''
                    kubectl rollout undo deployment/todo-app \
                      -n ${DEPLOY_ENV}
                '''
            }
        }
        always {
            // Clean up
            cleanWs()
        }
    }
}
```

---

## Lab 2: Multi-Environment Pipeline

```groovy
pipeline {
    agent {
        kubernetes {
            yamlFile 'jenkins-pod.yaml'
        }
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment'
        )
        booleanParam(
            name: 'RUN_TESTS',
            defaultValue: true,
            description: 'Run test suite'
        )
    }
    
    environment {
        AWS_REGION = 'ap-southeast-1'
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/todo-app"
    }
    
    stages {
        stage('Build') {
            steps {
                echo "Building for ${params.ENVIRONMENT}"
                // Build steps
            }
        }
        
        stage('Test') {
            when {
                expression { params.RUN_TESTS == true }
            }
            steps {
                echo 'Running tests'
                // Test steps
            }
        }
        
        stage('Deploy to Dev') {
            when {
                expression { params.ENVIRONMENT == 'dev' }
            }
            steps {
                echo 'Deploying to dev'
                // Deploy steps
            }
        }
        
        stage('Deploy to Staging') {
            when {
                expression { params.ENVIRONMENT == 'staging' }
            }
            steps {
                input message: 'Deploy to staging?', ok: 'Deploy'
                echo 'Deploying to staging'
                // Deploy steps
            }
        }
        
        stage('Deploy to Production') {
            when {
                expression { params.ENVIRONMENT == 'production' }
            }
            steps {
                input message: 'Deploy to PRODUCTION?', ok: 'Deploy'
                echo 'Deploying to production'
                // Deploy steps with extra validation
            }
        }
    }
}
```

---

## Lab 3: Configure Git Webhooks

### GitHub Webhook

1. Go to your repository on GitHub
2. Settings → Webhooks → Add webhook
3. Payload URL: `http://YOUR_JENKINS_URL/github-webhook/`
4. Content type: `application/json`
5. Events: "Just the push event"
6. Active: ✓
7. Add webhook

### Jenkins Configuration

1. Go to job configuration
2. Under "Build Triggers":
   - Check "GitHub hook trigger for GITScm polling"
3. Save

### Test Webhook

```bash
# Make a commit and push
echo "test" >> README.md
git add README.md
git commit -m "Test webhook"
git push

# Check Jenkins - should trigger automatically
```

---

## Lab 4: Add Notifications

### Slack Integration

```groovy
post {
    success {
        slackSend(
            color: 'good',
            message: "✅ Pipeline succeeded: ${env.JOB_NAME} ${env.BUILD_NUMBER}\nCommit: ${env.GIT_COMMIT_MSG}"
        )
    }
    failure {
        slackSend(
            color: 'danger',
            message: "❌ Pipeline failed: ${env.JOB_NAME} ${env.BUILD_NUMBER}\nCommit: ${env.GIT_COMMIT_MSG}"
        )
    }
}
```

### Email Notification

```groovy
post {
    always {
        emailext(
            subject: "${currentBuild.result}: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: """
                Build: ${env.BUILD_NUMBER}
                Status: ${currentBuild.result}
                Commit: ${env.GIT_COMMIT}
                Message: ${env.GIT_COMMIT_MSG}
                
                Check console output at: ${env.BUILD_URL}
            """,
            to: 'team@example.com'
        )
    }
}
```

---

## 💡 Best Practices

```yaml
Pipeline Best Practices:
├── Version control Jenkinsfile (in repo)
├── Use declarative syntax
├── Fail fast (tests before build)
├── Use shared libraries for common code
├── Implement proper error handling
├── Add meaningful logging
├── Clean workspace after build
└── Tag images with Git commit SHA

Security:
├── Scan images for vulnerabilities
├── Use least privilege service accounts
├── Store secrets in Jenkins credentials
├── Never commit credentials to Git
└── Enable audit logging

Performance:
├── Use Docker layer caching
├── Parallelize independent stages
├── Clean up old images
└── Use resource limits on agents
```

---

## ✅ Knowledge Check

- [ ] Create production-ready Jenkinsfile
- [ ] Configure multi-environment pipeline
- [ ] Set up Git webhooks
- [ ] Add notifications
- [ ] Implement rollback strategy

---

## 🚀 Next

**Continue to:** [09-04-Automated-Deployment.md](09-04-Automated-Deployment.md)

---

**Awesome!** Your CI/CD pipeline is production-ready! 🚀

