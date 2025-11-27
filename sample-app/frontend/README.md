# Todo Frontend

Simple HTML/CSS/JavaScript frontend for Todo application.

## Features

- Clean, modern UI
- Responsive design
- Connects to backend API
- Health status display
- Error handling

## Local Development

```bash
# Serve with any HTTP server
python3 -m http.server 8080 --directory src

# Or use nginx
docker build -t todo-frontend .
docker run -p 8080:8080 -e BACKEND_URL=http://localhost:3000 todo-frontend
```

## Docker Build

```bash
# Build image
docker build -t todo-frontend:latest .

# Run container
docker run -p 8080:8080 todo-frontend:latest

# Test
open http://localhost:8080
```

## Environment Variables

Configure backend URL by setting `window.BACKEND_URL` or use default `http://localhost:3000`.

In Kubernetes, this is configured via ConfigMap.

## For Kubernetes

This frontend is designed to be deployed in Kubernetes with:
- nginx web server
- Health check endpoint
- Security headers
- Gzip compression
- Runs as non-root user
- Small Alpine-based image

