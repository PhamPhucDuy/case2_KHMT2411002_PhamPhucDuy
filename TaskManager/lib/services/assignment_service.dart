import 'api_client.dart';

class AssignmentService {
  final ApiClient _api = ApiClient();

  Future<List<Map<String, dynamic>>> searchUsers(String keyword) async {
    final query = Uri.encodeQueryComponent(keyword.trim());
    dynamic data = await _api.get('/users/search?q=$query');

    for (int i = 0; i < 5; i++) {
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (data is Map) {
        data = data['users'] ?? data['data'] ?? data['results'] ?? data['items'];
      } else {
        break;
      }
    }
    throw ApiException('Định dạng kết quả tìm người dùng chưa phù hợp.');
  }

  Future<void> assignUsers({
    required String taskId,
    required List<String> userIds,
    required String primaryUserId,
  }) async {
    if (userIds.isEmpty || !userIds.contains(primaryUserId)) {
      throw ApiException('Hãy chọn người nhận và người phụ trách chính.');
    }
    await _api.post('/tasks/${Uri.encodeComponent(taskId)}/assignees', {
      // Neu backend su dung ten truong khac, sua hai key o day.
      'assigneeIds': userIds,
      'primaryAssigneeId': primaryUserId,
    });
  }
}