import 'api_client.dart';

class ProfileService {
  final ApiClient _api = ApiClient();

  // Lay thong tin tai khoan
  Future<Map<String, dynamic>> getProfile() async {
    dynamic data = await _api.get('/auth/me');

    for (int i = 0; i < 4; i++) {
      if (data is! Map) break;

      if (data.containsKey('fullName') ||
          data.containsKey('email')) {
        return Map<String, dynamic>.from(data);
      }

      data = data['user'] ??
          data['data'] ??
          data['profile'];
    }

    throw ApiException(
      'Kh\u00F4ng l\u1EA5y \u0111\u01B0\u1EE3c d\u1EEF li\u1EC7u h\u1ED3 s\u01A1',
    );
  }

  // Cap nhat ho ten
  Future<void> updateProfile(String fullName) async {
    await _api.put('/auth/me', {
      'fullName': fullName.trim(),
    });
  }

  // Doi mat khau
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}