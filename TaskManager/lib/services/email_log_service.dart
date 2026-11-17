import 'api_client.dart';

class EmailLogService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getLogs(
    String taskId,
  ) async {
    dynamic data = await _api.get(
      '/tasks/${Uri.encodeComponent(taskId)}/email-logs',
    );

    for (int i = 0; i < 5; i++) {
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (data is Map) {
        data = data['emailLogs'] ??
            data['logs'] ??
            data['data'] ??
            data['items'] ??
            data['results'];
      } else {
        break;
      }
    }

    throw ApiException(
      'Du lieu lich su email khong hop le',
    );
  }
}