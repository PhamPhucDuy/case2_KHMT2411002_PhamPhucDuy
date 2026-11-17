import 'package:flutter/material.dart';
import '../../services/task_checklist_service.dart';

class TaskChecklistScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskChecklistScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskChecklistScreen> createState() => _TaskChecklistScreenState();
}

class _TaskChecklistScreenState extends State<TaskChecklistScreen> {
  final _service = TaskChecklistService();
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.taskId);
  }

  Future<void> _refresh() async {
    final next = _service.load(widget.taskId);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder displays loading errors.
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
      if (!mounted) return;
      await _refresh();
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Th\u00EAm b\u01B0\u1EDBc c\u00F4ng vi\u1EC7c'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            hintText: 'V\u00ED d\u1EE5: Chu\u1EA9n b\u1ECB slide',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('H\u1EE7y'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Th\u00EAm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || title == null || title.trim().isEmpty) return;
    await _run(() => _service.add(widget.taskId, title));
  }

  Future<void> _delete(String id) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('X\u00F3a b\u01B0\u1EDBc n\u00E0y?'),
        content: const Text('Thao t\u00E1c n\u00E0y kh\u00F4ng th\u1EC3 ho\u00E0n t\u00E1c.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('H\u1EE7y'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('X\u00F3a'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _run(() => _service.remove(widget.taskId, id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist c\u00F4ng vi\u1EC7c'),
        actions: [
          IconButton(
            tooltip: 'L\u00E0m m\u1EDBi',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Th\u1EED l\u1EA1i'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};
          final items = (data['items'] is List ? data['items'] as List : [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final summary = data['summary'] is Map
              ? Map<String, dynamic>.from(data['summary'] as Map)
              : <String, dynamic>{};
          final total = (summary['total'] as num?)?.toInt() ?? items.length;
          final completed = (summary['completed'] as num?)?.toInt() ??
              items.where((item) => item['done'] == true).length;
          final percent = (summary['percent'] as num?)?.toInt() ??
              (total == 0 ? 0 : (100 * completed / total).round());
          final canManage = data['canManage'] == true;
          final canToggle = data['canToggle'] == true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.taskTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text('$completed / $total b\u01B0\u1EDBc \u0111\u00E3 ho\u00E0n th\u00E0nh - $percent%'),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: percent.clamp(0, 100) / 100),
              if (_busy) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 20),
              if (canManage)
                FilledButton.icon(
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Th\u00EAm b\u01B0\u1EDBc'),
                ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('Ch\u01B0a c\u00F3 b\u01B0\u1EDBc c\u00F4ng vi\u1EC7c n\u00E0o')),
                ),
              for (final item in items)
                Card(
                  child: CheckboxListTile(
                    title: Text(item['title']?.toString() ?? ''),
                    value: item['done'] == true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: !canToggle || _busy
                        ? null
                        : (value) {
                            final id = (item['_id'] ?? item['id'])?.toString() ?? '';
                            if (id.isEmpty) return;
                            _run(() => _service.setDone(
                                  widget.taskId,
                                  id,
                                  value ?? false,
                                ));
                          },
                    secondary: canManage
                        ? IconButton(
                            tooltip: 'X\u00F3a b\u01B0\u1EDBc',
                            onPressed: _busy
                                ? null
                                : () {
                                    final id = (item['_id'] ?? item['id'])?.toString() ?? '';
                                    if (id.isNotEmpty) _delete(id);
                                  },
                            icon: const Icon(Icons.delete_outline),
                          )
                        : null,
                  ),
                ),
              if (!canManage && !canToggle)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text('B\u1EA1n ch\u1EC9 c\u00F3 quy\u1EC1n xem checklist.'),
                ),
            ],
          );
        },
      ),
    );
  }
}