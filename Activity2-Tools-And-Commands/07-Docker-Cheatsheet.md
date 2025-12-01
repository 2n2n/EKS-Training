# Docker Commands Cheatsheet

Quick reference for Docker commands used throughout this training module.

---

## 📦 Image Management

### Building Images

```bash
# Build image from Dockerfile
docker build -t myapp:v1 .

# Build with specific Dockerfile
docker build -f Dockerfile.prod -t myapp:v1 .

# Build without cache
docker build --no-cache -t myapp:v1 .

# Build with build arguments
docker build --build-arg NODE_ENV=production -t myapp:v1 .

# Build multi-platform image
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:v1 .
```

### Listing and Inspecting Images

```bash
# List all images
docker images

# List images with filters
docker images --filter "dangling=false"
docker images --filter "reference=myapp:*"

# Show image details
docker inspect myapp:v1

# Show image history (layers)
docker history myapp:v1

# Show image disk usage
docker system df
```

### Pulling Images

```bash
# Pull from Docker Hub
docker pull nginx:latest
docker pull node:18-alpine

# Pull specific version
docker pull postgres:14

# Pull from private registry
docker pull myregistry.com/myapp:v1
```

### Tagging Images

```bash
# Tag image
docker tag myapp:v1 myapp:latest

# Tag for registry
docker tag myapp:v1 myregistry.com/myapp:v1

# Tag with multiple names
docker tag myapp:v1 myapp:latest
docker tag myapp:v1 myapp:stable
```

### Pushing Images

```bash
# Push to Docker Hub
docker push username/myapp:v1

# Push to private registry
docker push myregistry.com/myapp:v1

# Push all tags
docker push --all-tags myapp
```

### Removing Images

```bash
# Remove single image
docker rmi myapp:v1

# Remove image by ID
docker rmi abc123def456

# Force remove
docker rmi -f myapp:v1

# Remove dangling images
docker image prune

# Remove all unused images
docker image prune -a

# Remove images with filter
docker image prune --filter "until=24h"
```

### Saving and Loading Images

```bash
# Save image to tar file
docker save myapp:v1 > myapp.tar
docker save -o myapp.tar myapp:v1

# Load image from tar file
docker load < myapp.tar
docker load -i myapp.tar

# Export container to tar
docker export mycontainer > container.tar

# Import from tar
docker import container.tar myapp:v1
```

---

## 🚀 Container Management

### Running Containers

```bash
# Run container (foreground)
docker run myapp:v1

# Run in background (detached)
docker run -d myapp:v1

# Run with name
docker run -d --name myapp myapp:v1

# Run with port mapping
docker run -d -p 8080:3000 myapp:v1
docker run -d -p 127.0.0.1:8080:3000 myapp:v1

# Run with environment variables
docker run -d -e NODE_ENV=production myapp:v1
docker run -d -e PORT=3000 -e DEBUG=true myapp:v1

# Run with environment file
docker run -d --env-file .env myapp:v1

# Run with volume mount
docker run -d -v /host/path:/container/path myapp:v1
docker run -d -v myvolume:/app/data myapp:v1

# Run with network
docker run -d --network mynetwork myapp:v1

# Run with restart policy
docker run -d --restart always myapp:v1
docker run -d --restart unless-stopped myapp:v1
docker run -d --restart on-failure:3 myapp:v1

# Run with resource limits
docker run -d --memory="512m" --cpus="1.0" myapp:v1

# Run with working directory
docker run -d -w /app myapp:v1

# Run with user
docker run -d --user 1001:1001 myapp:v1

# Run with hostname
docker run -d --hostname myapp myapp:v1

# Run interactively
docker run -it myapp:v1 /bin/sh

# Run and remove after exit
docker run --rm myapp:v1
```

### Listing Containers

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List containers with size
docker ps -s

# List only container IDs
docker ps -q

# List with filters
docker ps --filter "name=myapp"
docker ps --filter "status=running"
docker ps --filter "label=env=production"

# Custom format output
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```

### Managing Running Containers

```bash
# Stop container
docker stop myapp

# Stop with timeout
docker stop -t 30 myapp

# Start stopped container
docker start myapp

# Restart container
docker restart myapp

# Pause container
docker pause myapp

# Unpause container
docker unpause myapp

# Kill container
docker kill myapp

# Kill with signal
docker kill -s SIGTERM myapp

# Rename container
docker rename old-name new-name

# Wait for container to stop
docker wait myapp
```

### Inspecting Containers

```bash
# View logs
docker logs myapp

# Follow logs (live)
docker logs -f myapp

# Show last N lines
docker logs --tail 100 myapp

# Show logs with timestamps
docker logs -t myapp

# Show logs since timestamp
docker logs --since 2024-01-01T00:00:00 myapp

# Inspect container details
docker inspect myapp

# Get specific field
docker inspect --format='{{.NetworkSettings.IPAddress}}' myapp

# View container processes
docker top myapp

# View container resource usage
docker stats myapp

# View all containers stats
docker stats

# View container changes
docker diff myapp

# View port mappings
docker port myapp
```

### Executing Commands in Containers

```bash
# Execute command
docker exec myapp ls -la

# Execute interactive shell
docker exec -it myapp /bin/sh
docker exec -it myapp /bin/bash

# Execute as specific user
docker exec -u root -it myapp /bin/sh

# Execute with environment variable
docker exec -e DEBUG=true myapp node script.js

# Execute in specific directory
docker exec -w /app myapp npm test
```

### Copying Files

```bash
# Copy from container to host
docker cp myapp:/app/file.txt ./file.txt

# Copy from host to container
docker cp ./file.txt myapp:/app/file.txt

# Copy directory
docker cp ./config myapp:/app/
docker cp myapp:/app/logs ./logs
```

### Removing Containers

```bash
# Remove stopped container
docker rm myapp

# Force remove running container
docker rm -f myapp

# Remove multiple containers
docker rm container1 container2 container3

# Remove all stopped containers
docker container prune

# Remove with filter
docker container prune --filter "until=24h"

# Remove all containers (dangerous!)
docker rm -f $(docker ps -aq)
```

---

## 🌐 Networking

### Network Management

```bash
# List networks
docker network ls

# Create network
docker network create mynetwork

# Create with driver
docker network create --driver bridge mynetwork

# Create with subnet
docker network create --subnet=172.18.0.0/16 mynetwork

# Inspect network
docker network inspect mynetwork

# Remove network
docker network rm mynetwork

# Remove unused networks
docker network prune

# Connect container to network
docker network connect mynetwork myapp

# Disconnect container from network
docker network disconnect mynetwork myapp
```

### DNS and Service Discovery

```bash
# Containers on same network can reach each other by name
docker network create mynetwork
docker run -d --name backend --network mynetwork backend:v1
docker run -d --name frontend --network mynetwork frontend:v1

# Frontend can reach backend at: http://backend:3000
```

---

## 💾 Volume Management

### Creating and Managing Volumes

```bash
# Create volume
docker volume create mydata

# List volumes
docker volume ls

# Inspect volume
docker volume inspect mydata

# Remove volume
docker volume rm mydata

# Remove unused volumes
docker volume prune

# Remove all volumes (dangerous!)
docker volume prune -a
```

### Using Volumes

```bash
# Named volume
docker run -d -v mydata:/app/data myapp:v1

# Bind mount
docker run -d -v /host/path:/container/path myapp:v1

# Read-only volume
docker run -d -v mydata:/app/data:ro myapp:v1

# Anonymous volume
docker run -d -v /app/data myapp:v1

# tmpfs mount (in-memory)
docker run -d --tmpfs /app/temp myapp:v1
```

---

## 🔐 AWS ECR Integration

### ECR Authentication

```bash
# Login to ECR (AWS CLI v2)
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.ap-southeast-1.amazonaws.com

# Login to ECR (AWS CLI v1 - deprecated)
$(aws ecr get-login --no-include-email --region ap-southeast-1)
```

### ECR Repository Management

```bash
# Create repository
aws ecr create-repository \
  --repository-name myapp \
  --region ap-southeast-1 \
  --image-scanning-configuration scanOnPush=true

# List repositories
aws ecr describe-repositories --region ap-southeast-1

# Delete repository
aws ecr delete-repository \
  --repository-name myapp \
  --region ap-southeast-1 \
  --force
```

### Working with ECR Images

```bash
# Tag for ECR
docker tag myapp:v1 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp:v1

# Push to ECR
docker push 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp:v1

# Pull from ECR
docker pull 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp:v1

# List images in repository
aws ecr list-images --repository-name myapp --region ap-southeast-1

# Describe images
aws ecr describe-images --repository-name myapp --region ap-southeast-1

# Delete image
aws ecr batch-delete-image \
  --repository-name myapp \
  --image-ids imageTag=v1 \
  --region ap-southeast-1
```

### Complete ECR Workflow

```bash
# Set variables
AWS_REGION="ap-southeast-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/myapp"

# Build image
docker build -t myapp:v1 .

# Tag for ECR
docker tag myapp:v1 ${ECR_REPO}:v1
docker tag myapp:v1 ${ECR_REPO}:latest

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

# Push to ECR
docker push ${ECR_REPO}:v1
docker push ${ECR_REPO}:latest

# Verify
aws ecr describe-images \
  --repository-name myapp \
  --region ${AWS_REGION}
```

---

## 🧹 Cleanup and Maintenance

### System Cleanup

```bash
# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune

# Remove all unused volumes
docker volume prune

# Remove all unused networks
docker network prune

# Remove everything (dangerous!)
docker system prune

# Remove everything including volumes (very dangerous!)
docker system prune -a --volumes

# Show disk usage
docker system df

# Show detailed disk usage
docker system df -v
```

### Targeted Cleanup

```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Remove dangling images
docker rmi $(docker images -f "dangling=true" -q)

# Remove containers older than 24 hours
docker container prune --filter "until=24h"
```

---

## 🔍 Debugging and Troubleshooting

### Logs and Monitoring

```bash
# View logs
docker logs myapp

# Follow logs
docker logs -f myapp

# Show last 100 lines
docker logs --tail 100 myapp

# Logs with timestamps
docker logs -t myapp

# Check container health
docker inspect --format='{{.State.Health.Status}}' myapp

# View events
docker events

# View events with filter
docker events --filter 'container=myapp'
```

### Container Inspection

```bash
# Get container IP
docker inspect --format='{{.NetworkSettings.IPAddress}}' myapp

# Get container ports
docker inspect --format='{{.NetworkSettings.Ports}}' myapp

# Get container environment
docker inspect --format='{{.Config.Env}}' myapp

# Get container status
docker inspect --format='{{.State.Status}}' myapp

# Check exit code
docker inspect --format='{{.State.ExitCode}}' myapp
```

### Interactive Debugging

```bash
# Shell into running container
docker exec -it myapp /bin/sh

# Shell as root
docker exec -u root -it myapp /bin/sh

# Run new container with shell
docker run -it --entrypoint /bin/sh myapp:v1

# Override entrypoint
docker run -it --entrypoint /bin/bash myapp:v1

# Check processes in container
docker top myapp

# Check resource usage
docker stats myapp

# Test network connectivity
docker exec myapp ping -c 3 backend
docker exec myapp curl http://backend:3000/health
```

---

## 🏗️ Docker Compose (Quick Reference)

### Basic Commands

```bash
# Start services
docker-compose up

# Start in background
docker-compose up -d

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# View logs
docker-compose logs

# Follow logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f backend

# List services
docker-compose ps

# Execute command in service
docker-compose exec backend sh

# Build images
docker-compose build

# Rebuild without cache
docker-compose build --no-cache

# Scale service
docker-compose up -d --scale backend=3
```

---

## 📝 Dockerfile Best Practices Commands

### Building Optimized Images

```bash
# Build with multi-stage
docker build -t myapp:v1 .

# Check image size
docker images myapp:v1

# Check layers
docker history myapp:v1

# Build with BuildKit (faster builds)
DOCKER_BUILDKIT=1 docker build -t myapp:v1 .

# Build with progress output
docker build --progress=plain -t myapp:v1 .

# Show build cache usage
docker builder prune
```

### Image Scanning

```bash
# Scan for vulnerabilities (Docker Hub)
docker scan myapp:v1

# Scan with specific severity
docker scan --severity high myapp:v1

# ECR image scanning
aws ecr start-image-scan \
  --repository-name myapp \
  --image-id imageTag=v1 \
  --region ap-southeast-1
```

---

## 🎯 Common Workflows

### Development Workflow

```bash
# 1. Build image
docker build -t todo-backend:latest .

# 2. Run locally
docker run -p 3000:3000 --name backend todo-backend:latest

# 3. Test
curl http://localhost:3000/health

# 4. View logs
docker logs -f backend

# 5. Debug
docker exec -it backend /bin/sh

# 6. Stop and cleanup
docker stop backend
docker rm backend
```

### Production Workflow

```bash
# 1. Build with version tag
docker build -t myapp:v1.2.3 .

# 2. Tag for registry
docker tag myapp:v1.2.3 ${ECR_REPO}:v1.2.3
docker tag myapp:v1.2.3 ${ECR_REPO}:latest

# 3. Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ECR_REPO}

# 4. Push to registry
docker push ${ECR_REPO}:v1.2.3
docker push ${ECR_REPO}:latest

# 5. Verify
aws ecr describe-images --repository-name myapp
```

### CI/CD Pipeline Commands

```groovy
// In Jenkins/CI pipeline
stage('Build') {
    sh 'docker build -t ${ECR_REPO}:${BUILD_NUMBER} .'
}

stage('Push') {
    sh '''
        aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REPO}
        docker push ${ECR_REPO}:${BUILD_NUMBER}
    '''
}
```

---

## 💡 Pro Tips

### Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'

# Cleanup
alias dprune='docker system prune -a'
alias dstop='docker stop $(docker ps -q)'
alias drm='docker rm $(docker ps -aq)'

# ECR login shortcut
alias ecr-login='aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-southeast-1.amazonaws.com'
```

### Docker Inspect Templates

```bash
# Get container IP
docker inspect -f '{{.NetworkSettings.IPAddress}}' myapp

# Get container state
docker inspect -f '{{.State.Status}}' myapp

# Get container mounts
docker inspect -f '{{json .Mounts}}' myapp | jq

# Get container environment
docker inspect -f '{{json .Config.Env}}' myapp | jq

# Get container ports
docker inspect -f '{{json .NetworkSettings.Ports}}' myapp | jq
```

### Resource Monitoring

```bash
# Monitor all containers
docker stats

# Monitor specific container
docker stats myapp

# Get resource usage once
docker stats --no-stream

# Custom format
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

---

## 🔗 Integration with Kubernetes

### Build for Kubernetes

```bash
# Build image
docker build -t myapp:v1 .

# Push to registry
docker push ${ECR_REPO}:v1

# Update Kubernetes deployment
kubectl set image deployment/myapp myapp=${ECR_REPO}:v1

# Verify rollout
kubectl rollout status deployment/myapp
```

### Pull from ECR in Kubernetes

```yaml
# Kubernetes pulls from ECR automatically with proper IAM roles
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: 123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/myapp:v1
```

---

## 📚 Additional Resources

### Getting Help

```bash
# Docker command help
docker --help

# Specific command help
docker build --help
docker run --help

# Docker version
docker version

# Docker info
docker info
```

### Official Documentation

- Docker Docs: https://docs.docker.com
- Docker Hub: https://hub.docker.com
- AWS ECR Docs: https://docs.aws.amazon.com/ecr

---

## ✅ Quick Command Summary

| Task             | Command                               |
| ---------------- | ------------------------------------- |
| Build image      | `docker build -t myapp:v1 .`          |
| Run container    | `docker run -d -p 8080:3000 myapp:v1` |
| List containers  | `docker ps`                           |
| View logs        | `docker logs -f myapp`                |
| Execute shell    | `docker exec -it myapp /bin/sh`       |
| Stop container   | `docker stop myapp`                   |
| Remove container | `docker rm myapp`                     |
| List images      | `docker images`                       |
| Remove image     | `docker rmi myapp:v1`                 |
| Push to ECR      | `docker push ${ECR_REPO}:v1`          |
| System cleanup   | `docker system prune -a`              |

---

**Happy Dockering! 🐳**
