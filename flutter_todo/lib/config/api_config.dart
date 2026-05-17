// Cấu hình URL Backend API
// Web (Chrome): dùng localhost
// Android Emulator: dùng 10.0.2.2
// Thiết bị thật: dùng IP máy tính (vd: 192.168.1.x)

const String baseUrl = 'http://localhost:3000';

// Auth endpoints
const String registerUrl = '$baseUrl/register';
const String loginUrl = '$baseUrl/login';

// Todo endpoints
const String todosUrl = '$baseUrl/todos';
