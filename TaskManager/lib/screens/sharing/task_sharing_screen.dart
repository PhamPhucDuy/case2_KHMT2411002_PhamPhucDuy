import 'package:flutter/material.dart';
import '../../services/task_share_service.dart';

class TaskSharingScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskSharingScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final _service = TaskShareService();
  final _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _selected = {};
  List<Map<String, dynamic>> _results = [];
  late Future<List<Map<String, dynamic>>> _sharesFuture;
  bool _searched = false;
  bool _searching = false;
  bool _busy = false;
  String _newPermission = 'viewer';

  @override
  void initState() {
    super.initState();
    _sharesFuture = _service.getShares(widget.taskId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _id(Map<String, dynamic> record) =>
      (record['_id'] ?? record['id'] ?? '').toString();

  String _name(Map<String, dynamic> user) =>
      (user['fullName'] ?? user['name'] ?? user['email'] ?? 'Người dùng').toString();

  Map<String, dynamic> _shareUser(Map<String, dynamic> share) {
    final value = share['userId'] ?? share['user'];
    if (value is Map) return Map<String, dynamic>.from(value);
    return share;
  }

  String _shareName(Map<String, dynamic> share) => _name(_shareUser(share));

  String _shareEmail(Map<String, dynamic> share) =>
      (_shareUser(share)['email'] ?? '').toString();

  String _permission(Map<String, dynamic> share) =>
      share['permission'] == 'editor' ? 'editor' : 'viewer';

  void _message(Object message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message')),
    );
  }

  Future<void> _reload() async {
    final next = _service.getShares(widget.taskId);
    setState(() { _sharesFuture = next; });
    try {
      await next;
    } catch (_) {
      // FutureBuilder sẽ hiển thị lỗi.
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (_searching || _busy) return;
    if (query.length < 2) {
      _message('Hãy nhập ít nhất 2 ký tự để tìm.');
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _service.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _results = results.where((u) => _id(u).isNotEmpty).toList();
        _searched = true;
      });
    } catch (e) {
      if (mounted) _message(e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _toggle(Map<String, dynamic> user, bool selected) {
    final id = _id(user);
    if (id.isEmpty) return;
    setState(() {
      if (selected) {
        _selected[id] = user;
      } else {
        _selected.remove(id);
      }
    });
  }

  Future<void> _addShares() async {
    if (_busy || _selected.isEmpty) {
      _message('Hãy chọn ít nhất một tài khoản.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.addShares(
        taskId: widget.taskId,
        userIds: _selected.keys.toList(),
        permission: _newPermission,
      );
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _results = [];
        _searched = false;
        _searchController.clear();
      });
      _message('Đã gửi yêu cầu chia sẻ thành công.');
      await _reload();
    } catch (e) {
      if (mounted) _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePermission(
    Map<String, dynamic> share,
    String permission,
  ) async {
    final shareId = _id(share);
    if (shareId.isEmpty || _busy) {
      _message('Không tìm thấy mã chia sẻ.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.changePermission(
        taskId: widget.taskId,
        shareId: shareId,
        permission: permission,
      );
      if (!mounted) return;
      _message('Đã cập nhật quyền truy cập.');
      await _reload();
    } catch (e) {
      if (mounted) _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeShare(Map<String, dynamic> share) async {
    if (_busy) return;
    final shareId = _id(share);
    if (shareId.isEmpty) {
      _message('Không tìm thấy mã chia sẻ.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thu hồi quyền chia sẻ?'),
        content: Text('Ngừng chia sẻ với ${_shareName(share)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      await _service.removeShare(taskId: widget.taskId, shareId: shareId);
      if (!mounted) return;
      _message('Đã thu hồi quyền chia sẻ.');
      await _reload();
    } catch (e) {
      if (mounted) _message(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _shareCard(Map<String, dynamic> share) {
    final shareId = _id(share);
    return Card(
      key: ValueKey(shareId),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_shareName(share),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_shareEmail(share).isNotEmpty) Text(_shareEmail(share)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('$shareId-${_permission(share)}'),
                    initialValue: _permission(share),
                    decoration: const InputDecoration(
                      labelText: 'Quyền truy cập',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem')),
                      DropdownMenuItem(value: 'editor', child: Text('Chỉnh sửa')),
                    ],
                    onChanged: _busy ? null : (value) {
                      if (value != null && value != _permission(share)) {
                        _changePermission(share, value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Thu hồi chia sẻ',
                  onPressed: _busy ? null : () => _removeShare(share),
                  icon: const Icon(Icons.person_remove_outlined),
                ),
              ],
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
        title: const Text('Quản lý chia sẻ'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
              labelText: 'Tìm người bằng họ tên hoặc email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _searching || _busy ? null : _search,
            icon: const Icon(Icons.person_search),
            label: Text(_searching ? 'Đang tìm...' : 'Tìm người dùng'),
          ),
          if (_searching) const LinearProgressIndicator(),
          if (_searched) ...[
            const SizedBox(height: 12),
            Text('Kết quả tìm kiếm: ${_results.length}'),
            if (_results.isEmpty)
              const Text('Không tìm thấy tài khoản phù hợp.'),
            for (final user in _results)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.containsKey(_id(user)),
                title: Text(_name(user)),
                subtitle: Text((user['email'] ?? '').toString()),
                onChanged: _busy ? null : (value) => _toggle(user, value ?? false),
              ),
          ],
          const SizedBox(height: 16),
          Text('Đã chọn: ${_selected.length} tài khoản'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _newPermission,
            decoration: const InputDecoration(
              labelText: 'Quyền cho người mới',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'viewer', child: Text('Chỉ xem (viewer)')),
              DropdownMenuItem(value: 'editor', child: Text('Chỉnh sửa (editor)')),
            ],
            onChanged: _busy ? null : (value) {
              if (value != null) setState(() => _newPermission = value);
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy || _selected.isEmpty ? null : _addShares,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Chia sẻ cho người đã chọn'),
          ),
          const Divider(height: 36),
          Text('Danh sách đã chia sẻ',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _sharesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Không tải được chia sẻ: ${snapshot.error}'),
                    TextButton(onPressed: _reload, child: const Text('Thử lại')),
                  ],
                );
              }
              final shares = snapshot.data ?? [];
              if (shares.isEmpty) return const Text('Chưa chia sẻ cho ai.');
              return Column(children: shares.map(_shareCard).toList());
            },
          ),
        ],
      ),
    );
  }
}