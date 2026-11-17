import 'package:flutter/material.dart';
import '../../services/task_service.dart';

class TaskEditScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskEditScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TaskService();

  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _priority;
  late DateTime _dueDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _title = TextEditingController(
      text: task['title']?.toString() ?? '',
    );

    _description = TextEditingController(
      text: task['description']?.toString() ?? '',
    );

    final priority = task['priority']?.toString();
    _priority = ['low', 'medium', 'high'].contains(priority)
        ? priority!
        : 'medium';

    final date = DateTime.tryParse(
      task['dueDate']?.toString() ?? '',
    );

    _dueDate = date?.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (result != null) {
      setState(() => _dueDate = result);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    final id = widget.task['_id']?.toString() ??
        widget.task['id']?.toString();

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu mã công việc')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.updateTask(
        taskId: id,
        title: _title.text,
        description: _description.text,
        priority: _priority,
        dueDate: _dueDate,
      );

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

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa công việc'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Tên công việc',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập tên công việc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Mô tả công việc',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'low',
                    child: Text('Thấp'),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text('Trung bình'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('Cao'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _priority = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving ? null : _chooseDate,
                icon: const Icon(Icons.calendar_month),
                label: Text('Hạn hoàn thành: $dateText'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(
                  _saving ? 'Đang lưu...' : 'Lưu thay đổi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}