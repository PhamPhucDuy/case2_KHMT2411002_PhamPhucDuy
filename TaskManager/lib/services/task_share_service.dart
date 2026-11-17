import 'api_client.dart';
import 'assignment_service.dart';

class TaskShareService {
  final ApiClient _api = ApiClient();
  final AssignmentService _users = AssignmentService();

  Future<List<Map<String, dynamic>>> searchUsers(String query) =>
      _users.searchUsers(query);

  Future<List<Map<String, dynamic>>> getShares(String taskId) async {
    dynamic data = await _api.get(
      '/tasks/${Uri.encodeComponent(taskId)}/shares',
    );
    for (var i = 0; i < 5; i++) {
      if (data is List) {
        return data.whereType<Map>().map(
          (e) => Map<String, dynamic>.from(e),
        ).toList();
      }
      if (data is Map) {
        data = data['shares'] ?? data['data'] ?? data['results'] ?? data['items'];
      } else {
        break;
      }
    }
    throw ApiException('Dữ liệu chia sẻ trả về không đúng định dạng.');
  }

  Future<void> addShares({
    required String taskId,
    required List<String> userIds,
    required String permission,
  }) async {
    if (userIds.isEmpty) throw ApiException('Chưa chọn tài khoản để chia sẻ.');
    if (permission != 'viewer' && permission != 'editor') {
      throw ApiException('Quyền chia sẻ không hợp lệ.');
    }
    // Đối chiếu req.body của taskShareController.js trước khi kiểm thử.
    await _api.post('/tasks/${Uri.encodeComponent(taskId)}/shares', {
      'userIds': userIds,
      'permission': permission,
    });
  }

  Future<void> changePermission({
    required String taskId,
    required String shareId,
    required String permission,
  }) async {
    await _api.patch(
      '/tasks/${Uri.encodeComponent(taskId)}/shares/${Uri.encodeComponent(shareId)}',
      {'permission': permission},
    );
  }

  Future<void> removeShare({
    required String taskId,
    required String shareId,
  }) async {
    await _api.delete(
      '/tasks/${Uri.encodeComponent(taskId)}/shares/${Uri.encodeComponent(shareId)}',
    );
  }
}