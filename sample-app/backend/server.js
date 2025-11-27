const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage for todos
let todos = [
  { id: 1, text: 'Learn Docker', completed: false },
  { id: 2, text: 'Learn Kubernetes', completed: false },
  { id: 3, text: 'Deploy to EKS', completed: false }
];

let nextId = 4;

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'backend', timestamp: new Date().toISOString() });
});

// Get all todos
app.get('/api/todos', (req, res) => {
  console.log('[GET] /api/todos - Returning all todos');
  res.json(todos);
});

// Get single todo
app.get('/api/todos/:id', (req, res) => {
  const todo = todos.find(t => t.id === parseInt(req.params.id));
  if (!todo) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  res.json(todo);
});

// Create todo
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
  console.log(`[POST] /api/todos - Created todo: ${text}`);
  res.status(201).json(newTodo);
});

// Update todo
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
  
  console.log(`[PUT] /api/todos/${req.params.id} - Updated todo`);
  res.json(todo);
});

// Delete todo
app.delete('/api/todos/:id', (req, res) => {
  const index = todos.findIndex(t => t.id === parseInt(req.params.id));
  if (index === -1) {
    return res.status(404).json({ error: 'Todo not found' });
  }
  
  todos.splice(index, 1);
  console.log(`[DELETE] /api/todos/${req.params.id} - Deleted todo`);
  res.status(204).send();
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Backend server running on port ${PORT}`);
  console.log(`📍 Health check: http://localhost:${PORT}/health`);
  console.log(`📍 API endpoint: http://localhost:${PORT}/api/todos`);
});

