# Todo Backend API

Simple Express.js REST API for Todo application.

## API Endpoints

### Health Check
```
GET /health
Response: { status: 'healthy', service: 'backend', timestamp: '...' }
```

### Get All Todos
```
GET /api/todos
Response: Array of todo objects
```

### Get Single Todo
```
GET /api/todos/:id
Response: Todo object or 404
```

### Create Todo
```
POST /api/todos
Body: { "text": "Your todo text" }
Response: Created todo object
```

### Update Todo
```
PUT /api/todos/:id
Body: { "text": "Updated text", "completed": true }
Response: Updated todo object
```

### Delete Todo
```
DELETE /api/todos/:id
Response: 204 No Content
```

## Local Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run production server
npm start
```

Server runs on port 3000 by default.

## Docker Build

```bash
# Build image
docker build -t todo-backend:latest .

# Run container
docker run -p 3000:3000 todo-backend:latest

# Test
curl http://localhost:3000/health
curl http://localhost:3000/api/todos
```

## Environment Variables

- `PORT`: Server port (default: 3000)
- `NODE_ENV`: Environment (development/production)

## For Kubernetes

This backend is designed to be deployed in Kubernetes with:
- Health check endpoint for liveness/readiness probes
- Graceful shutdown
- Runs as non-root user
- Small Alpine-based image

