import 'api_client.dart';

class TaskActivityService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> getActivities(
    String taskId,
  ) async {
    dynamic data = await _api.get(
      '/tasks/${Uri.encodeComponent(taskId)}/activities',
    );

    for (int i = 0; i < 5; i++) {
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      }

      if (data is Map) {
        data = data['activities'] ??
            data['data'] ??
            data['items'] ??
            data['results'];
      } else {
        break;
      }
    }

    throw ApiException(
      'Du lieu lich su khong hop le',
    );
  }
}