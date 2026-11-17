import 'package:flutter/material.dart';
import '../../services/assignment_service.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const AssignTaskScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _service = AssignmentService();
  final _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _selected = {};
  List<Map<String, dynamic>> _results = [];
  String? _primaryId;
  bool _searching = false;
  bool _submitting = false;
  bool _searched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _id(Map<String, dynamic> user) =>
      (user['_id'] ?? user['id'] ?? '').toString();

  String _name(Map<String, dynamic> user) =>
      (user['fullName'] ?? user['name'] ?? user['email'] ?? 'Người dùng').toString();

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _search() async {
    final text = _searchController.text.trim();
    if (_searching || _submitting) return;
    if (text.length < 2) {
      _message('Hãy nhập ít nhất 2 ký tự để tìm kiếm.');
      return;
    }

    setState(() => _searching = true);
    try {
      final users = await _service.searchUsers(text);
      if (!mounted) return;
      setState(() {
        _results = users.where((u) => _id(u).isNotEmpty).toList();
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      _message('$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _toggle(Map<String, dynamic> user, bool checked) {
    final id = _id(user);
    if (id.isEmpty) return;
    setState(() {
      if (checked) {
        _selected[id] = user;
        _primaryId ??= id;
      } else {
        _selected.remove(id);
        if (_primaryId == id) {
          _primaryId = _selected.isEmpty ? null : _selected.keys.first;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selected.isEmpty || _primaryId == null) {
      _message('Hãy chọn người nhận và người phụ trách chính.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.assignUsers(
        taskId: widget.taskId,
        userIds: _selected.keys.toList(),
        primaryUserId: _primaryId!,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _message('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao công việc')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.taskTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: const InputDecoration(
              labelText: 'Tìm tài khoản theo tên hoặc email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _searching ? null : _search,
            icon: const Icon(Icons.person_search),
            label: Text(_searching ? 'Đang tìm...' : 'Tìm người dùng'),
          ),
          if (_searching) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          if (_searched) ...[
            Text('Kết quả tìm kiếm (${_results.length})',
                style: Theme.of(context).textTheme.titleMedium),
            if (_results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Không tìm thấy tài khoản phù hợp.'),
              ),
            for (final user in _results)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.containsKey(_id(user)),
                title: Text(_name(user)),
                subtitle: Text((user['email'] ?? '').toString()),
                onChanged: (value) => _toggle(user, value ?? false),
              ),
          ],
          const Divider(height: 32),
          Text('Đã chọn: ${_selected.length} người',
              style: Theme.of(context).textTheme.titleMedium),
          if (_selected.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Chọn ít nhất một người trong kết quả tìm kiếm.'),
            ),
          for (final entry in _selected.entries)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(_name(entry.value)),
              subtitle: Text((entry.value['email'] ?? '').toString()),
              trailing: IconButton(
                tooltip: 'Bỏ chọn',
                icon: const Icon(Icons.close),
                onPressed: () => _toggle(entry.value, false),
              ),
            ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Chọn người phụ trách chính:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final entry in _selected.entries)
                  ChoiceChip(
                    label: Text(_name(entry.value)),
                    selected: _primaryId == entry.key,
                    onSelected: (value) {
                      if (value) setState(() => _primaryId = entry.key);
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.send),
            label: Text(_submitting ? 'Đang giao việc...' : 'Xác nhận giao việc'),
          ),
        ],
      ),
    );
  }
}