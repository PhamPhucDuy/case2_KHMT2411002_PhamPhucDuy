import 'api_client.dart';

class TaskCommentService {
  final ApiClient _api = ApiClient();

  String _path(String taskId) =>
      '/tasks/${Uri.encodeComponent(taskId)}/comments';

  Future<Map<String, dynamic>> load(String taskId) async {
    final data = await _api.get(_path(taskId));
    if (data is Map && data['comments'] is List) {
      return Map<String, dynamic>.from(data);
    }
    throw ApiException('D\u1EEF li\u1EC7u b\u00ECnh lu\u1EADn kh\u00F4ng h\u1EE3p l\u1EC7');
  }

  Future<void> add(String taskId, String text) async {
    await _api.post(_path(taskId), {'text': text});
  }

  Future<void> edit(String taskId, String commentId, String text) async {
    await _api.patch(
      '${_path(taskId)}/${Uri.encodeComponent(commentId)}',
      {'text': text},
    );
  }

  Future<void> remove(String taskId, String commentId) async {
    await _api.delete('${_path(taskId)}/${Uri.encodeComponent(commentId)}');
  }
}