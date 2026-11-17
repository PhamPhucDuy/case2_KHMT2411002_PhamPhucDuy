
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  // 1. Đăng ký tài khoản
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _api.post('/auth/register', {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  // 2. Đăng nhập tài khoản
  Future<void> login(String email, String password) async {
    final response = await _api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    if (response is! Map) {
      throw ApiException('Phản hồi đăng nhập không hợp lệ.');
    }

    final nested = response['data'];

    final token = response['token'] ??
        response['accessToken'] ??
        (nested is Map
            ? (nested['token'] ?? nested['accessToken'])
            : null);

    if (token is! String || token.isEmpty) {
      throw ApiException('Máy chủ không trả về token đăng nhập.');
    }

    await _api.saveToken(token);
  }

  // 3. Đăng xuất
  Future<void> logout() => _api.clearToken();
}
