import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/todo_model.dart';
import 'auth_service.dart';

class TodoService {
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Lấy danh sách todo
  static Future<List<TodoModel>> getTodos() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse(todosUrl), headers: headers);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      final List list = data['data'];
      return list.map((item) => TodoModel.fromJson(item)).toList();
    }
    throw Exception(data['message'] ?? 'Không thể tải danh sách todo');
  }

  // Tạo todo mới (có priority và dueDate)
  static Future<TodoModel> createTodo(
    String title,
    String description, {
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'title': title,
      'description': description,
      'priority': priority,
      if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
    };
    final response = await http.post(
      Uri.parse(todosUrl),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['status'] == true) {
      return TodoModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Không thể tạo todo');
  }

  // Cập nhật todo
  static Future<TodoModel> updateTodo(
    String id,
    String title,
    String description, {
    String priority = 'medium',
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    final headers = await _authHeaders();
    final body = {
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': clearDueDate ? null : dueDate?.toIso8601String(),
    };
    final response = await http.put(
      Uri.parse('$todosUrl/$id'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return TodoModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Không thể cập nhật todo');
  }

  // Xóa todo
  static Future<bool> deleteTodo(String id) async {
    final headers = await _authHeaders();
    final response =
        await http.delete(Uri.parse('$todosUrl/$id'), headers: headers);
    final data = jsonDecode(response.body);
    return response.statusCode == 200 && data['status'] == true;
  }

  // Toggle hoàn thành
  static Future<TodoModel> toggleTodo(String id) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$todosUrl/$id/toggle'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return TodoModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Không thể cập nhật trạng thái');
  }

  // Xóa tất cả todo đã hoàn thành
  static Future<int> deleteCompleted() async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$todosUrl/completed'),
      headers: headers,
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      return data['deletedCount'] ?? 0;
    }
    throw Exception(data['message'] ?? 'Không thể xóa');
  }
}
