import 'api_client.dart';

class TaskChecklistService {
  final ApiClient _api = ApiClient();

  String _base(String taskId) =>
      '/tasks/${Uri.encodeComponent(taskId)}/checklist';

  Future<Map<String, dynamic>> load(String taskId) async {
    final data = await _api.get(_base(taskId));
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('D\u1EEF li\u1EC7u checklist kh\u00F4ng h\u1EE3p l\u1EC7');
  }

  Future<void> add(String taskId, String title) async {
    await _api.post(_base(taskId), {'title': title});
  }

  Future<void> setDone(
    String taskId, String itemId, bool done,
  ) async {
    await _api.patch(
      '${_base(taskId)}/${Uri.encodeComponent(itemId)}',
      {'done': done},
    );
  }

  Future<void> remove(String taskId, String itemId) async {
    await _api.delete(
      '${_base(taskId)}/${Uri.encodeComponent(itemId)}',
    );
  }
}