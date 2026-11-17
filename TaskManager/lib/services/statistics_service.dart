import 'api_client.dart';

class StatisticsService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> getTaskStats() async =>
      Map<String, dynamic>.from(await _api.get('/statistics/tasks'));

  Future<Map<String, dynamic>> getAssignmentStats() async =>
      Map<String, dynamic>.from(await _api.get('/statistics/assignments'));

  Future<Map<String, dynamic>> getDeadlineStats() async =>
      Map<String, dynamic>.from(await _api.get('/statistics/deadlines'));

  Future<List<dynamic>> getActivities(String taskId) async {
    final data = await _api.get('/tasks/$taskId/activities');
    return data is List ? data : (data['activities'] ?? data['data'] ?? []);
  }
}