const router = require('express').Router();
const TodoController = require('../controllers/todo.controller');
const { verifyToken } = require('../middleware/auth.middleware');

// Tất cả routes đều cần JWT token
router.use(verifyToken);

// QUAN TRỌNG: Route /completed phải đặt TRƯỚC /:id
// để tránh nhầm "completed" với một ID

// DELETE /todos/completed - Xóa tất cả todo hoàn thành
router.delete('/todos/completed', TodoController.deleteCompleted);

// GET /todos - Lấy danh sách todo
router.get('/todos', TodoController.getTodos);

// POST /todos - Tạo todo mới
router.post('/todos', TodoController.createTodo);

// PUT /todos/:id - Cập nhật todo
router.put('/todos/:id', TodoController.updateTodo);

// DELETE /todos/:id - Xóa todo
router.delete('/todos/:id', TodoController.deleteTodo);

// PATCH /todos/:id/toggle - Toggle trạng thái
router.patch('/todos/:id/toggle', TodoController.toggleTodo);

module.exports = router;
