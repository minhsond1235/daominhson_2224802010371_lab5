const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const UserRoutes = require('./routes/user.routes');
const TodoRoutes = require('./routes/todo.routes');

const app = express();

// Middleware - CORS: cho phép tất cả origin (dev mode)
app.use(cors({
  origin: function (origin, callback) {
    // Cho phép tất cả request (kể cả không có origin như Postman, Flutter web)
    callback(null, true);
  },
  allowedHeaders: ['Content-Type', 'Authorization'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  credentials: true,
}));
app.options('*', cors()); // Xử lý preflight OPTIONS request
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Health check
app.get('/', (req, res) => {
  res.json({
    status: true,
    message: '🚀 Todo API Server đang chạy!',
    version: '1.0.0',
  });
});

// Routes
app.use('/', UserRoutes);
app.use('/', TodoRoutes);

// Error handler
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message);
  res.status(err.status || 500).json({
    status: false,
    message: err.message || 'Lỗi server nội bộ',
  });
});

module.exports = app;
