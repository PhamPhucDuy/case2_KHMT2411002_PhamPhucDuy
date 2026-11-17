import 'api_client.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  // Lay danh sach thong bao
  Future<List<Map<String, dynamic>>> getNotifications() async {
    dynamic data = await _api.get('/notifications');

    for (int i = 0; i < 5; i++) {
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (data is Map) {
        data = data['notifications'] ??
            data['data'] ??
            data['items'] ??
            data['results'];
      } else {
        break;
      }
    }

    throw ApiException(
      'Dữ liệu thông báo không hợp lệ',
    );
  }

  // Danh dau mot thong bao da doc
  Future<void> markAsRead(String id) async {
    await _api.patch(
      '/notifications/${Uri.encodeComponent(id)}/read',
      <String, dynamic>{},
    );
  }

  // Danh dau tat ca da doc
  Future<void> markAllAsRead() async {
    await _api.patch(
      '/notifications/read-all',
      <String, dynamic>{},
    );
  }

  // Lay chi tiet cong viec lien quan
  Future<Map<String, dynamic>> getTask(
    String taskId,
  ) async {
    dynamic data = await _api.get(
      '/tasks/${Uri.encodeComponent(taskId)}',
    );

    for (int i = 0; i < 5; i++) {
      if (data is! Map) break;

      if (data['_id'] != null || data['id'] != null) {
        return Map<String, dynamic>.from(data);
      }

      data = data['task'] ??
          data['data'] ??
          data['result'];
    }

    throw ApiException(
      'Không tìm thấy dữ liệu công việc',
    );
  }
}