const TodoService = require('../services/todo.service');

// GET /todos - Lấy danh sách todo của user
exports.getTodos = async (req, res, next) => {
  try {
    const todos = await TodoService.getTodosByUser(req.userId);
    res.json({ status: true, data: todos });
  } catch (err) {
    next(err);
  }
};

// POST /todos - Tạo todo mới
exports.createTodo = async (req, res, next) => {
  try {
    const { title, description, priority, dueDate } = req.body;

    if (!title) {
      return res.status(400).json({
        status: false,
        message: 'Tiêu đề là bắt buộc',
      });
    }

    const todo = await TodoService.createTodo(req.userId, {
      title,
      description: description || '',
      priority: priority || 'medium',
      dueDate: dueDate ? new Date(dueDate) : null,
    });

    res.status(201).json({ status: true, data: todo });
  } catch (err) {
    next(err);
  }
};

// PUT /todos/:id - Cập nhật todo
exports.updateTodo = async (req, res, next) => {
  try {
    const { title, description, isCompleted, priority, dueDate } = req.body;

    const updated = await TodoService.updateTodo(req.params.id, req.userId, {
      title,
      description,
      isCompleted,
      priority,
      dueDate: dueDate ? new Date(dueDate) : null,
    });

    if (!updated) {
      return res.status(404).json({
        status: false,
        message: 'Không tìm thấy todo hoặc bạn không có quyền sửa',
      });
    }

    res.json({ status: true, data: updated });
  } catch (err) {
    next(err);
  }
};

// DELETE /todos/:id - Xóa todo
exports.deleteTodo = async (req, res, next) => {
  try {
    const deleted = await TodoService.deleteTodo(req.params.id, req.userId);

    if (!deleted) {
      return res.status(404).json({
        status: false,
        message: 'Không tìm thấy todo hoặc bạn không có quyền xóa',
      });
    }

    res.json({ status: true, message: 'Xóa todo thành công' });
  } catch (err) {
    next(err);
  }
};

// PATCH /todos/:id/toggle - Toggle trạng thái hoàn thành
exports.toggleTodo = async (req, res, next) => {
  try {
    const toggled = await TodoService.toggleComplete(req.params.id, req.userId);

    if (!toggled) {
      return res.status(404).json({
        status: false,
        message: 'Không tìm thấy todo',
      });
    }

    res.json({ status: true, data: toggled });
  } catch (err) {
    next(err);
  }
};

// DELETE /todos/completed - Xóa tất cả todo đã hoàn thành
exports.deleteCompleted = async (req, res, next) => {
  try {
    const result = await TodoService.deleteAllCompleted(req.userId);
    res.json({
      status: true,
      message: `Đã xóa ${result.deletedCount} todo hoàn thành`,
      deletedCount: result.deletedCount,
    });
  } catch (err) {
    next(err);
  }
};
