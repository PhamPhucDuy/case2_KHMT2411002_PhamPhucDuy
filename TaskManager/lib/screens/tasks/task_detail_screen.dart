import 'package:flutter/material.dart';
import 'task_email_log_screen.dart';
import 'task_activity_screen.dart';
import '../sharing/task_sharing_screen.dart';
import '../assignment/assign_task_screen.dart';
import 'task_edit_screen.dart';
import '../../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _service = TaskService();

  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.task['status']?.toString();

    _status = [
      'todo',
      'in_progress',
      'completed',
    ].contains(initial)
        ? initial!
        : 'todo';
  }

  String _priorityName(dynamic value) {
    switch (value) {
      case 'low':
        return 'Thấp';
      case 'medium':
        return 'Trung bình';
      case 'high':
        return 'Cao';
      default:
        return 'Chưa xác định';
    }
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) return 'Chưa đặt';

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_saving || newStatus == _status) return;

    final taskId =
        widget.task['_id']?.toString() ??
        widget.task['id']?.toString();

    if (taskId == null || taskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã công việc'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.updateStatus(taskId, newStatus);

      if (!mounted) return;

      setState(() => _status = newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trạng thái thành công'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }


  Future<void> _editTask() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditScreen(task: widget.task),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteTask() async {
    if (_saving) return;

    final id = widget.task['_id']?.toString() ??
        widget.task['id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu mã công việc')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: const Text(
          'Bạn có chắc muốn xóa công việc này? '
          'Hành động không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    try {
      await _service.deleteTask(id);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _information(
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    final title =
        task['title']?.toString() ?? 'Không có tiêu đề';

    final description =
        task['description']?.toString() ?? '';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Giao vi\u1EC7c'),
        onPressed: () async {
          final id = (widget.task['_id'] ?? widget.task['id'])?.toString();
          if (id == null || id.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kh\u00F4ng t\u00ECm th\u1EA5y m\u00E3 c\u00F4ng vi\u1EC7c')),
            );
            return;
          }
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AssignTaskScreen(
                taskId: id,
                taskTitle: (widget.task['title'] ?? '').toString(),
              ),
            ),
          );
          if (!context.mounted) return;
          if (saved == true) {
            Navigator.pop(context, true);
          }
        },
      ),
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          IconButton(
            tooltip: 'L\u1ECBch s\u1EED g\u1EEDi email',
            icon: const Icon(Icons.email_outlined),
            onPressed: () {
              final id = (
                widget.task['_id'] ??
                widget.task['id']
              )?.toString();

              if (id == null || id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kh\u00F4ng t\u00ECm th\u1EA5y m\u00E3 c\u00F4ng vi\u1EC7c',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TaskEmailLogScreen(
                    taskId: id,
                    taskTitle: (
                      widget.task['title'] ?? ''
                    ).toString(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'L\u1ECBch s\u1EED ho\u1EA1t \u0111\u1ED9ng',
            icon: const Icon(Icons.history),
            onPressed: () {
              final id = (
                widget.task['_id'] ??
                widget.task['id']
              )?.toString();

              if (id == null || id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Kh\u00F4ng t\u00ECm th\u1EA5y m\u00E3 c\u00F4ng vi\u1EC7c',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TaskActivityScreen(
                    taskId: id,
                    taskTitle: (
                      widget.task['title'] ?? ''
                    ).toString(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Quản lý chia sẻ',
            icon: const Icon(Icons.people_outline),
            onPressed: () {
              final id = (widget.task['_id'] ?? widget.task['id'])?.toString();
              if (id == null || id.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Không tìm thấy mã công việc')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskSharingScreen(
                    taskId: id,
                    taskTitle: (widget.task['title'] ?? '').toString(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sửa công việc',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _saving ? null : _editTask,
          ),
          IconButton(
            tooltip: 'Xóa công việc',
            icon: const Icon(Icons.delete_outline),
            onPressed: _saving ? null : _deleteTask,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Divider(height: 30),

                  _information(
                    'Mô tả',
                    description.isEmpty
                        ? 'Chưa có mô tả'
                        : description,
                    Icons.description_outlined,
                  ),

                  _information(
                    'Mức độ ưu tiên',
                    _priorityName(task['priority']),
                    Icons.flag_outlined,
                  ),

                  _information(
                    'Ngày bắt đầu',
                    _formatDate(task['startDate']),
                    Icons.event_available,
                  ),

                  _information(
                    'Hạn hoàn thành',
                    _formatDate(task['dueDate']),
                    Icons.event_busy_outlined,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái công việc',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    key: ValueKey("$_status-$_saving"),
                    initialValue: _status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sync_alt),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'todo',
                        child: Text('Chưa thực hiện'),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('Đang thực hiện'),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Đã hoàn thành'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              _changeStatus(value);
                            }
                          },
                  ),

                  if (_saving) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Đang lưu trạng thái...'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}