import 'package:flutter/material.dart';

import 'task_search_screen.dart';
import '../../services/task_service.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _service = TaskService();

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getTasks();
  }

  Future<void> _refresh() async {
    final next = _service.getTasks();
    setState(() {
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder sẽ hiển thị lỗi.
    }
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm công việc thành công')),
      );
      await _refresh();
    }
  }

  String _status(dynamic value) {
    switch (value) {
      case 'todo':
        return 'Chưa thực hiện';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return 'Không xác định';
    }
  }

  String _priority(dynamic value) {
    switch (value) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return 'Chưa đặt';
    }
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');

    if (parsed == null) return 'Chưa đặt';

    final d = parsed.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách công việc'),
        actions: [
          IconButton(
            tooltip: 'T\u00ECm ki\u1EBFm, l\u1ECDc v\u00E0 s\u1EAFp x\u1EBFp',
            icon: const Icon(Icons.manage_search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TaskSearchScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _refresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  const Text('Chưa có công việc nào'),
                  const SizedBox(height: 15),
                  FilledButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm công việc'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                final title = task['title']?.toString() ?? 'Không có tiêu đề';

                final description = task['description']?.toString() ?? '';

                return Card(
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(task: task),
                        ),
                      );

                      if (mounted) {
                        await _refresh();
                      }
                    },
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (description.isNotEmpty) Text(description),
                        Text('Trạng thái: ${_status(task['status'])}'),
                        Text('Ưu tiên: ${_priority(task['priority'])}'),
                        Text('Hạn: ${_date(task['dueDate'])}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
