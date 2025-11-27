# Docker Basics: Understanding Containers

**Estimated Reading Time: 30 minutes**

---

## 🐳 What is Docker?

Docker is a platform for building, shipping, and running applications in **containers**.

**Simple analogy:** Think of Docker containers like shipping containers for your code.

---

## 📦 Containers vs Virtual Machines

### Your Current Setup: Probably VMs or Bare Metal

#### Virtual Machine (What You Might Use Now)

```
┌──────────────────────────────────────┐
│     Physical Server / Hypervisor     │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────┐    ┌────────────┐  │
│  │   VM 1     │    │   VM 2     │  │
│  │            │    │            │  │
│  │  Full OS   │    │  Full OS   │  │
│  │  (Ubuntu)  │    │  (Ubuntu)  │  │
│  │            │    │            │  │
│  │  Your App  │    │  Your App  │  │
│  │  2GB RAM   │    │  2GB RAM   │  │
│  │  20GB Disk │    │  20GB Disk │  │
│  └────────────┘    └────────────┘  │
└──────────────────────────────────────┘

Each VM:
✅ Complete isolation
❌ Heavy (full OS)
❌ Slow to start (minutes)
❌ Large disk usage
```

#### Containers (Docker Way)

```
┌──────────────────────────────────────┐
│        Physical Server / VM          │
├──────────────────────────────────────┤
│         Host Operating System        │
├──────────────────────────────────────┤
│          Docker Engine               │
├──────────────────────────────────────┤
│                                      │
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │ App  │  │ App  │  │ App  │      │
│  │  1   │  │  2   │  │  3   │      │
│  │      │  │      │  │      │      │
│  │ Libs │  │ Libs │  │ Libs │      │
│  └──────┘  └──────┘  └──────┘      │
│    Container  Container  Container  │
│    100MB      100MB      100MB      │
└──────────────────────────────────────┘

Each Container:
✅ Lightweight (shares OS kernel)
✅ Fast to start (seconds)
✅ Small disk usage
✅ Good isolation
❌ Less isolation than VMs
```

---

## 🤔 Why Use Containers?

### Problem 1: "Works on My Machine" Syndrome

**Traditional way:**

```
Developer's Laptop:
- Node.js 18.0
- npm 9.0
- Ubuntu 22.04
- "It works!"

Production Server:
- Node.js 16.0
- npm 8.0
- CentOS 7
- "It doesn't work!" 😱
```

**With Docker:**

```
Developer's Laptop:
- Runs container with Node 18, npm 9, Ubuntu 22.04
- "It works!"

Production Server:
- Runs SAME container with Node 18, npm 9, Ubuntu 22.04
- "It works!" 🎉

Container = Exact same environment everywhere
```

### Problem 2: Complex Dependencies

**Traditional installation:**

```bash
# Your app needs:
apt-get install -y nodejs npm python3 build-essential
apt-get install -y libpq-dev imagemagick redis-server
npm install
pip3 install requirements.txt

# 30 minutes later...
# Did I install everything?
# What versions?
# Did I document this?
```

**With Docker:**

```dockerfile
# Dockerfile - Everything documented
FROM node:18
RUN apt-get update && apt-get install -y imagemagick
COPY package.json .
RUN npm install
COPY . .
CMD ["node", "server.js"]

# Build once, run anywhere
# All dependencies included
# Self-documenting
```

### Problem 3: Server Pollution

**Traditional server over time:**

```
Server after 2 years:
- Old dependencies you forgot about
- Multiple Node.js versions
- Leftover packages from testing
- Configuration files everywhere
- "Why is this here?"
- "Can I delete this?"

Server = Accumulates cruft
```

**With Docker:**

```
Container lifecycle:
1. Start clean container
2. Run your app
3. Stop container
4. Delete container
5. Start fresh again

Container = Always clean
```

---

## 🏗️ Docker Core Concepts

### 1. Docker Image (The Blueprint)

**Like:** A class in programming, a recipe for cooking

```
Docker Image
├── Base OS (e.g., Ubuntu 22.04)
├── Node.js 18
├── Your application code
├── Dependencies (node_modules)
└── Configuration

Read-only template
Built from Dockerfile
Stored in registry (Docker Hub, ECR)
```

**Analogy:**

```
Traditional:           Docker:
Installer CD     →     Docker Image
Installation     →     Container creation
Running program  →     Running container
```

### 2. Docker Container (The Running Instance)

**Like:** An object instance, a cooked meal

```
Container = Running Image

From image "myapp:v1":
- Container 1: Running
- Container 2: Running
- Container 3: Running

Same image, multiple containers
Each isolated from others
```

### 3. Dockerfile (The Recipe)

**Like:** Installation instructions, cooking recipe

```dockerfile
# Dockerfile - Instructions to build image

# Start with base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Expose port
EXPOSE 3000

# Command to run
CMD ["node", "server.js"]
```

**Traditional equivalent:**

```bash
# Your manual installation script
# 1. Install Node.js 18
# 2. Create /app directory
# 3. Copy package.json
# 4. Run npm install
# 5. Copy application
# 6. Start on port 3000
# 7. Run node server.js
```

---

## 📝 Real Example: Todo App

### Traditional Deployment

```bash
# On production server
ssh user@server

# Install Node.js
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone app
cd /var/www
git clone https://github.com/user/todo-app
cd todo-app

# Install dependencies
npm install

# Set environment
export PORT=3000
export NODE_ENV=production

# Start app
pm2 start server.js

# Problems:
# - What if server already has Node 16?
# - What if npm install fails?
# - Did you document all this?
```

### Docker Deployment

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

CMD ["node", "server.js"]
```

```bash
# Build image (once)
docker build -t todo-app:v1 .

# Run anywhere
docker run -p 3000:3000 todo-app:v1

# Benefits:
# - Same environment every time
# - All dependencies included
# - Documented in Dockerfile
# - Takes 30 seconds to deploy
```

---

## 🔧 Basic Docker Commands

### Working with Images

```bash
# Build image from Dockerfile
docker build -t myapp:v1 .

# List images on your machine
docker images

# Pull image from registry
docker pull nginx:latest

# Remove image
docker rmi myapp:v1

# Push to registry (Docker Hub, ECR)
docker push myapp:v1
```

### Working with Containers

```bash
# Run container
docker run -d -p 3000:3000 --name myapp myapp:v1
# -d: Run in background
# -p: Port mapping (host:container)
# --name: Give it a name

# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View logs
docker logs myapp
docker logs -f myapp  # Follow logs

# Stop container
docker stop myapp

# Start stopped container
docker start myapp

# Remove container
docker rm myapp

# Execute command in running container
docker exec -it myapp bash
# Like SSH, but into container
```

---

## 🎯 Dockerfile Best Practices

### Multi-Stage Builds (Smaller Images)

```dockerfile
# Bad: Everything in one stage (500MB+)
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["node", "server.js"]

# Good: Multi-stage build (100MB)
# Stage 1: Build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Production
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app .
CMD ["node", "server.js"]
```

### Layer Caching (Faster Builds)

```dockerfile
# Bad: Copy everything first
FROM node:18
WORKDIR /app
COPY . .              # Changes every time
RUN npm install       # Runs every time
CMD ["node", "server.js"]

# Good: Copy dependencies first
FROM node:18
WORKDIR /app
COPY package*.json ./  # Changes rarely
RUN npm install        # Cached if package.json unchanged
COPY . .               # Changes often
CMD ["node", "server.js"]
```

### Use .dockerignore

```
# .dockerignore - Don't copy these into image
node_modules
npm-debug.log
.git
.env
.DS_Store
README.md
```

**Like:** `.gitignore` but for Docker

---

## 🌐 Container Networking

### Port Mapping

```bash
# Your container runs on port 3000 inside
# Map to port 8080 on host
docker run -p 8080:3000 myapp

# Access:
# - From host: http://localhost:8080
# - From outside: http://server-ip:8080
# - Inside container: http://localhost:3000
```

**Traditional equivalent:**

```
Like setting up nginx reverse proxy:
External :8080 → Internal :3000
```

### Container Communication

```bash
# Create network
docker network create mynetwork

# Run database container
docker run -d --network mynetwork \
  --name postgres postgres:14

# Run app container
docker run -d --network mynetwork \
  --name myapp \
  -e DATABASE_HOST=postgres \
  myapp:v1

# App can reach database at "postgres:5432"
# Like hosts in same network
```

---

## 💾 Persistent Data

### Problem: Containers are Ephemeral

```bash
# Start container
docker run --name mydb postgres:14

# Add data to database
# ...

# Stop and remove container
docker stop mydb
docker rm mydb

# Data is GONE! 😱
```

### Solution: Volumes

```bash
# Create volume
docker volume create postgres-data

# Run container with volume
docker run -d --name mydb \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:14

# Stop and remove container
docker stop mydb
docker rm mydb

# Data is still in volume! ✅

# Start new container with same volume
docker run -d --name mydb2 \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:14

# Data is back! 🎉
```

**Traditional equivalent:**

```
Like mounting external disk:
/dev/sdb1 → /var/lib/postgresql/data
Disk persists even if server rebuilds
```

---

## 🔐 Environment Variables & Secrets

### Passing Configuration

```bash
# Method 1: Command line
docker run -e DATABASE_URL=postgresql://... myapp

# Method 2: Environment file
# .env file
DATABASE_URL=postgresql://localhost/mydb
API_KEY=secret123

docker run --env-file .env myapp

# Method 3: In Dockerfile (not for secrets!)
# Dockerfile
ENV NODE_ENV=production
```

**Like:** Setting environment variables in `.bashrc` or `.env` file

---

## 🚀 Real Workflow Example

### Development to Production

```bash
# 1. Develop locally
# Write code
vim server.js

# 2. Create Dockerfile
# Define how to build your app
vim Dockerfile

# 3. Build image
docker build -t todo-app:v1 .

# 4. Test locally
docker run -p 3000:3000 todo-app:v1
# Visit http://localhost:3000

# 5. Push to registry
docker tag todo-app:v1 myregistry/todo-app:v1
docker push myregistry/todo-app:v1

# 6. Deploy to production
# On production server:
docker pull myregistry/todo-app:v1
docker run -d -p 80:3000 myregistry/todo-app:v1

# Same image, works exactly the same!
```

---

## 📊 Comparison Summary

| Aspect | Traditional | Docker |
|--------|-------------|--------|
| **Setup time** | 30-60 min | 1-2 min |
| **Consistency** | "Works on my machine" | "Works everywhere" |
| **Documentation** | Manual wiki/readme | Self-documenting Dockerfile |
| **Isolation** | Server-level | Container-level |
| **Portability** | Hard to move | Easy to move |
| **Cleanup** | Manual uninstall | Delete container |
| **Disk usage** | Accumulates over time | Clean every time |
| **Version control** | Hard | Easy (image tags) |

---

## 🤔 Common Questions

### "Do I still need VMs?"

**Yes!** Containers run ON TOP of VMs or bare metal:

```
Cloud Provider (AWS)
└── Virtual Machine (EC2)
    └── Docker Engine
        └── Containers (Your apps)
```

### "Can I SSH into containers?"

**Yes, but you shouldn't need to:**

```bash
# You can:
docker exec -it mycontainer bash

# But better:
docker logs mycontainer  # View logs
docker inspect mycontainer  # See config
```

### "What about databases?"

**Options:**

1. **Run in container (dev/testing)**
   ```bash
   docker run -d postgres:14
   ```

2. **Managed service (production)**
   ```
   AWS RDS, not in container
   More reliable for production
   ```

### "Are containers secure?"

**Generally yes, but:**
- ✅ Good isolation for normal apps
- ⚠️ Share kernel with host
- ❌ Less isolation than VMs
- 🔐 Don't run untrusted code

---

## ✅ Key Takeaways

### Containers Are:
- ✅ Lightweight VMs (sort of)
- ✅ Portable ("build once, run anywhere")
- ✅ Fast to start/stop
- ✅ Self-documenting (Dockerfile)
- ✅ Consistent environments

### Containers Solve:
- ✅ "Works on my machine" problem
- ✅ Complex dependency management
- ✅ Environment consistency
- ✅ Deployment reliability

### Containers Require:
- 📚 Learning Docker commands
- 🏗️ Writing Dockerfiles
- 🔄 New deployment workflow
- 💾 Understanding storage (volumes)

---

## 🎓 What You've Learned

- What containers are (and aren't)
- How they differ from VMs
- Why they're useful
- Basic Docker concepts (images, containers)
- How to write a Dockerfile
- Common Docker commands
- Real-world workflows

---

## 🚀 Next Steps

You now understand Docker and containers!

**In Kubernetes:**
- Kubernetes manages Docker containers
- You define what containers to run
- Kubernetes handles starting/stopping/restarting
- All in a cluster of many servers

**Next:** [03-Kubernetes-Concepts.md](03-Kubernetes-Concepts.md) - Learn how Kubernetes orchestrates containers!

---

**Remember:** Containers are just packaged applications. You're already familiar with the concepts! 📦

