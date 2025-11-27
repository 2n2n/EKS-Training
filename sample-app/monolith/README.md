# Todo Monolith Application

Single container application with Frontend and Backend combined.

## Architecture

```
┌─────────────────────────────┐
│     Monolith Container      │
│                             │
│  ┌───────────────────────┐  │
│  │   Frontend (HTML)     │  │
│  │   Served by Express   │  │
│  └───────────────────────┘  │
│             ▲               │
│             │               │
│  ┌───────────────────────┐  │
│  │   Backend (Express)   │  │
│  │   REST API            │  │
│  └───────────────────────┘  │
│             ▲               │
│             │               │
│  ┌───────────────────────┐  │
│  │   Data (In-Memory)    │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
```

## Usage

### Local Development

```bash
# Install dependencies
npm install

# Run application
npm start

# Access at http://localhost:3000
```

### Docker

```bash
# Build image
docker build -t todo-monolith:latest .

# Run container
docker run -p 3000:3000 todo-monolith:latest

# Access at http://localhost:3000
```

### Kubernetes

```bash
# Deploy (use in Activity 3)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-monolith
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo
  template:
    metadata:
      labels:
        app: todo
    spec:
      containers:
      - name: todo
        image: todo-monolith:latest
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: todo-service
spec:
  type: NodePort
  selector:
    app: todo
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30080
EOF
```

## Pros and Cons

### Pros ✅
- Simple to develop and deploy
- Single codebase
- No network latency between components
- Easy to understand
- Good for small applications

### Cons ❌
- Can't scale components independently
- Single point of failure
- Entire app must be deployed for any change
- Hard to use different technologies
- Becomes complex as it grows

## Comparison with Microservices

This monolith version is used in **Activity 3** for learning.

The microservices version (Activity 4) separates:
- Frontend → Separate container
- Backend → Separate container

Benefits of microservices:
- Independent scaling
- Independent deployment
- Failure isolation
- Technology flexibility

Use monoliths when:
- Small application
- Simple requirements
- Single team
- Rapid prototyping

Use microservices when:
- Large application
- Multiple teams
- Need independent scaling
- Different technology needs

