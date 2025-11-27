const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// In-memory storage for todos
let todos = [
  { id: 1, text: 'Learn Docker', completed: false },
  { id: 2, text: 'Learn Kubernetes', completed: false },
  { id: 3, text: 'Deploy to EKS', completed: false }
];

let nextId = 4;

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    service: 'monolith', 
    timestamp: new Date().toISOString() 
  });
});

// API Routes
app.get('/api/todos', (req, res) => {
  console.log('[GET] /api/todos');
  res.json(todos);
});

app.get('/api/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  res.json(todo);
});

app.post('/api/todos', (req, res) => {
  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ error: 'Text is required' });
  }
  
  const newTodo = {
    id: nextId++,
    text,
    completed: false
  };
  
  todos.push(newTodo);
  console.log(`[POST] /api/todos - Created: ${text}`);
  res.status(201).json(newTodo);
});

app.put('/api/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  
  if (req.body.text !== undefined) {
    todo.text = req.body.text;
  }
  if (req.body.completed !== undefined) {
    todo.completed = req.body.completed;
  }
  
  console.log(`[PUT] /api/todos/${req.params.id}`);
  res.json(todo);
});

app.delete('/api/todos/:id', (req, res) => {
  const index = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  
  todos.splice(index, 1);
  console.log(`[DELETE] /api/todos/${req.params.id}`);
  res.status(204).send();
});

// Serve frontend for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Monolith Todo App running on port ${PORT}`);
  console.log(`📍 Web UI: http://localhost:${PORT}`);
  console.log(`📍 API: http://localhost:${PORT}/api/todos`);
  console.log(`📍 Health: http://localhost:${PORT}/health`);
});

