import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  // Lưu token vào SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Lấy token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Xóa token (đăng xuất)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Đăng ký tài khoản
  static Future<Map<String, dynamic>> register(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 201, 'data': data};
    } catch (e) {
      return {
        'success': false,
        'data': {'message': 'Không thể kết nối đến server: $e'}
      };
    }
  }

  // Đăng nhập
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        // Lưu token
        await saveToken(data['token']);
        return {'success': true, 'data': data};
      }

      return {'success': false, 'data': data};
    } catch (e) {
      return {
        'success': false,
        'data': {'message': 'Không thể kết nối đến server: $e'}
      };
    }
  }
}
