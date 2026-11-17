import 'api_client.dart';

class TaskService {
  final ApiClient _api = ApiClient();

  // Lấy danh sách công việc
  Future<List<Map<String, dynamic>>> getTasks() async {
    dynamic data = await _api.get('/tasks');

    for (int i = 0; i < 4; i++) {
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (data is Map) {
        data = data['tasks'] ??
            data['data'] ??
            data['items'] ??
            data['results'];
      } else {
        break;
      }
    }

    throw ApiException(
      'Dữ liệu danh sách công việc không hợp lệ',
    );
  }

  // Thêm công việc mới
  Future<void> createTask({
    required String title,
    required String description,
    required String priority,
    required DateTime dueDate,
  }) async {
    final deadline = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23, 59, 59,
    );

    await _api.post('/tasks', {
      'title': title.trim(),
      'description': description.trim(),
      'priority': priority,
      'status': 'todo',
      'startDate': DateTime.now().toUtc().toIso8601String(),
      'dueDate': deadline.toUtc().toIso8601String(),
    });
  }

  // Cap nhat trang thai cong viec
  Future<void> updateStatus(
    String taskId,
    String status,
  ) async {
    await _api.patch(
      '/tasks/${Uri.encodeComponent(taskId)}/status',
      {'status': status},
    );
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    required DateTime dueDate,
  }) async {
    final deadline = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23, 59, 59,
    );

    await _api.put(
      '/tasks/${Uri.encodeComponent(taskId)}',
      {
        'title': title.trim(),
        'description': description.trim(),
        'priority': priority,
        'dueDate': deadline.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    await _api.delete(
      '/tasks/${Uri.encodeComponent(taskId)}',
    );
  }
}
