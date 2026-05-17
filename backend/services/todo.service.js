const Todo = require('../models/todo.model');

class TodoService {
  static async getTodosByUser(userId) {
    return await Todo.find({ userId }).sort({ createdAt: -1 });
  }

  static async createTodo(userId, { title, description, priority, dueDate }) {
    const todo = new Todo({ userId, title, description, priority, dueDate });
    return await todo.save();
  }

  static async updateTodo(todoId, userId, updateData) {
    // Lọc bỏ field undefined
    const cleanData = Object.fromEntries(
      Object.entries(updateData).filter(([_, v]) => v !== undefined)
    );
    return await Todo.findOneAndUpdate(
      { _id: todoId, userId },
      cleanData,
      { new: true }
    );
  }

  static async deleteTodo(todoId, userId) {
    return await Todo.findOneAndDelete({ _id: todoId, userId });
  }

  static async toggleComplete(todoId, userId) {
    const todo = await Todo.findOne({ _id: todoId, userId });
    if (!todo) return null;
    todo.isCompleted = !todo.isCompleted;
    return await todo.save();
  }

  // Xóa tất cả todo đã hoàn thành của user
  static async deleteAllCompleted(userId) {
    return await Todo.deleteMany({ userId, isCompleted: true });
  }
}

module.exports = TodoService;
