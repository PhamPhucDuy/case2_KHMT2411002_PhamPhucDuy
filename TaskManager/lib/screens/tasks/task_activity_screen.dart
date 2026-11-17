import 'package:flutter/material.dart';
import '../../services/task_activity_service.dart';

class TaskActivityScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskActivityScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskActivityScreen> createState() =>
      _TaskActivityScreenState();
}

class _TaskActivityScreenState
    extends State<TaskActivityScreen> {
  final _service = TaskActivityService();

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getActivities(widget.taskId);
  }

  Future<void> _refresh() async {
    final next = _service.getActivities(widget.taskId);

    setState(() {
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder se hien thi loi.
    }
  }

  String _actionLabel(dynamic value) {
    final action = (value ?? '')
        .toString()
        .toLowerCase();

    switch (action) {
      case 'create':
      case 'created':
      case 'task_created':
        return 'T\u1EA1o c\u00F4ng vi\u1EC7c';

      case 'update':
      case 'updated':
      case 'task_updated':
        return 'Ch\u1EC9nh s\u1EEDa c\u00F4ng vi\u1EC7c';

      case 'status_change':
      case 'status_changed':
      case 'update_status':
        return 'Thay \u0111\u1ED5i tr\u1EA1ng th\u00E1i';

      case 'assign':
      case 'assigned':
      case 'assignment':
        return 'Giao c\u00F4ng vi\u1EC7c';

      case 'share':
      case 'shared':
        return 'Chia s\u1EBB c\u00F4ng vi\u1EC7c';

      case 'delete':
      case 'deleted':
        return 'X\u00F3a c\u00F4ng vi\u1EC7c';

      default:
        return action.isEmpty
            ? 'Ho\u1EA1t \u0111\u1ED9ng'
            : action.replaceAll('_', ' ');
    }
  }

  IconData _actionIcon(dynamic value) {
    final action = (value ?? '')
        .toString()
        .toLowerCase();

    if (action.contains('status')) {
      return Icons.sync_alt;
    }

    if (action.contains('assign')) {
      return Icons.assignment_ind_outlined;
    }

    if (action.contains('share')) {
      return Icons.people_outline;
    }

    if (action.contains('creat')) {
      return Icons.add_task;
    }

    if (action.contains('updat') ||
        action.contains('edit')) {
      return Icons.edit_outlined;
    }

    return Icons.history;
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    String two(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${two(local.day)}/${two(local.month)}/${local.year}'
        ' - ${two(local.hour)}:${two(local.minute)}';
  }

  String _actorName(Map<String, dynamic> activity) {
    final user = activity['userId'] ??
        activity['user'] ??
        activity['performedBy'];

    if (user is Map) {
      return (user['fullName'] ??
              user['name'] ??
              user['email'] ??
              '')
          .toString();
    }

    return '';
  }

  String _detailsText(dynamic value) {
    if (value == null) return '';

    if (value is String) return value;

    if (value is Map) {
      return value.entries
          .where(
            (entry) =>
                entry.value != null &&
                entry.value is! Map &&
                entry.value is! List,
          )
          .take(5)
          .map(
            (entry) => '${entry.key}: ${entry.value}',
          )
          .join('\n');
    }

    return '';
  }

  Widget _activityCard(Map<String, dynamic> activity) {
    final action = activity['action'];

    final title = _actionLabel(action);

    final actor = _actorName(activity);

    final date = _date(activity['createdAt']);

    final details = _detailsText(
      activity['details'],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Icon(
                _actionIcon(action),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  if (actor.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      actor,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ],

                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(details),
                  ],

                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'L\u1ECBch s\u1EED ho\u1EA1t \u0111\u1ED9ng',
        ),
        actions: [
          IconButton(
            tooltip: 'L\u00E0m m\u1EDBi',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Th\u1EED l\u1EA1i'),
                  ),
                ],
              ),
            );
          }

          final activities = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.taskTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                if (activities.isEmpty) ...[
                  const SizedBox(height: 100),

                  const Icon(
                    Icons.history,
                    size: 65,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      'Ch\u01B0a c\u00F3 l\u1ECBch s\u1EED',
                    ),
                  ),
                ] else
                  ...activities.map(_activityCard),
              ],
            ),
          );
        },
      ),
    );
  }
}