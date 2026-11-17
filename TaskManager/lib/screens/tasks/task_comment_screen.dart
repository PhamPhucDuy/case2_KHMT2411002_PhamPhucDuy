import 'package:flutter/material.dart';
import '../../services/task_comment_service.dart';

class TaskCommentScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskCommentScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskCommentScreen> createState() => _TaskCommentScreenState();
}

class _TaskCommentScreenState extends State<TaskCommentScreen> {
  final _service = TaskCommentService();
  final _messageInput = TextEditingController();
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.taskId);
  }

  @override
  void dispose() {
    _messageInput.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _service.load(widget.taskId);
    setState(() { _future = next; });
    try { await next; } catch (_) { /* FutureBuilder shows errors. */ }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _run(Future<void> Function() operation, {bool clear = false}) async {
    if (_busy) return;
    setState(() { _busy = true; });
    try {
      await operation();
      if (!mounted) return;
      if (clear) _messageInput.clear();
      await _refresh();
    } catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _send() async {
    final text = _messageInput.text.trim();
    if (text.isEmpty || text.length > 1000) {
      _show('B\u00ECnh lu\u1EADn ph\u1EA3i t\u1EEB 1 \u0111\u1EBFn 1000 k\u00FD t\u1EF1');
      return;
    }
    await _run(() => _service.add(widget.taskId, text), clear: true);
  }

  Future<void> _edit(Map<String, dynamic> comment) async {
    if (_busy) return;
    final id = (comment['_id'] ?? '').toString();
    if (id.isEmpty) return;
    final controller = TextEditingController(text: (comment['text'] ?? '').toString());
    final changed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('S\u1EEDa b\u00ECnh lu\u1EADn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 1000,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('H\u1EE7y'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('L\u01B0u'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || changed == null || changed.isEmpty) return;
    await _run(() => _service.edit(widget.taskId, id, changed));
  }

  Future<void> _remove(Map<String, dynamic> comment) async {
    if (_busy) return;
    final id = (comment['_id'] ?? '').toString();
    if (id.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('X\u00F3a b\u00ECnh lu\u1EADn?'),
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
    if (!mounted || ok != true) return;
    await _run(() => _service.remove(widget.taskId, id));
  }

  String _name(Map<String, dynamic> comment) {
    final user = comment['userId'];
    if (user is Map) {
      return (user['fullName'] ?? user['email'] ?? 'Th\u00E0nh vi\u00EAn').toString();
    }
    return 'Th\u00E0nh vi\u00EAn';
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}'
        ' ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _commentCard(Map<String, dynamic> comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle_outlined, size: 27),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_name(comment),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (comment['canEdit'] == true)
                  IconButton(
                    tooltip: 'S\u1EEDa b\u00ECnh lu\u1EADn',
                    onPressed: _busy ? null : () => _edit(comment),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (comment['canDelete'] == true)
                  IconButton(
                    tooltip: 'X\u00F3a b\u00ECnh lu\u1EADn',
                    onPressed: _busy ? null : () => _remove(comment),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text((comment['text'] ?? '').toString()),
            const SizedBox(height: 8),
            Text(_date(comment['createdAt']),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('B\u00ECnh lu\u1EADn c\u00F4ng vi\u1EC7c'),
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
                padding: const EdgeInsets.all(16),
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

          final data = snapshot.data ?? {};
          final raw = (data['comments'] as List?) ?? [];
          final comments = raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final canComment = data['canComment'] == true;

          return Column(
            children: [
              if (_busy) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(widget.taskTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: comments.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Icon(Icons.forum_outlined, size: 56, color: Colors.grey),
                            SizedBox(height: 16),
                            Center(child: Text('Ch\u01B0a c\u00F3 b\u00ECnh lu\u1EADn')),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: comments.length,
                          itemBuilder: (_, index) => _commentCard(comments[index]),
                        ),
                ),
              ),
              SafeArea(
                top: false,
                child: canComment
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageInput,
                                enabled: !_busy,
                                minLines: 1,
                                maxLines: 3,
                                maxLength: 1000,
                                decoration: const InputDecoration(
                                  hintText: 'Nh\u1EADp b\u00ECnh lu\u1EADn...',
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: 'G\u1EEDi b\u00ECnh lu\u1EADn',
                              onPressed: _busy ? null : _send,
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('B\u1EA1n ch\u1EC9 c\u00F3 quy\u1EC1n xem b\u00ECnh lu\u1EADn'),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}