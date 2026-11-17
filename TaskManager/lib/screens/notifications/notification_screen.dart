import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();

  late Future<List<Map<String, dynamic>>> _future;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getNotifications();
  }

  String _id(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value?.toString() ?? '';
  }

  String _notificationId(Map<String, dynamic> item) {
    return _id(item['_id'] ?? item['id']);
  }

  String _taskId(Map<String, dynamic> item) {
    return _id(item['taskId'] ?? item['task']);
  }

  bool _isRead(Map<String, dynamic> item) {
    return item['isRead'] == true ||
        item['read'] == true ||
        item['readAt'] != null;
  }

  String _formatDate(dynamic value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) return '';

    final local = date.toLocal();

    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year}'
        ' ${two(local.hour)}:${two(local.minute)}';
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Tai lai danh sach thong bao
  Future<void> _refresh() async {
    final next = _service.getNotifications();

    setState(() {
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder hien thi loi.
    }
  }

  // Danh dau tat ca thong bao da doc
  Future<void> _markAllRead() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      await _service.markAllAsRead();

      if (!mounted) return;

      _message('Đã đánh dấu tất cả thông báo là đã đọc');
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      _message(error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Nhan vao thong bao de mo cong viec lien quan
  Future<void> _openNotification(
    Map<String, dynamic> item,
  ) async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final notificationId = _notificationId(item);

      if (!_isRead(item) && notificationId.isNotEmpty) {
        await _service.markAsRead(notificationId);
      }

      final taskId = _taskId(item);

      if (taskId.isNotEmpty) {
        final task = await _service.getTask(taskId);

        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(
              task: task,
            ),
          ),
        );
      }

      if (!mounted) return;

      await _refresh();
    } catch (error) {
      if (!mounted) return;
      _message(error.toString());
      await _refresh();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  // Hien thi mot thong bao
  Widget _buildNotification(
    Map<String, dynamic> item,
  ) {
    final read = _isRead(item);

    final title = (
      item['title'] ?? 'Thông báo'
    ).toString();

    final message = (
      item['message'] ?? ''
    ).toString();

    final createdAt = _formatDate(item['createdAt']);

    return Card(
      color: read ? null : Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.45),

      margin: const EdgeInsets.only(bottom: 10),

      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: Icon(
          read
              ? Icons.notifications_none
              : Icons.notifications_active,
          color: read ? Colors.grey : Colors.indigo,
        ),

        title: Text(
          title,
          style: TextStyle(
            fontWeight: read
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            Text(message),

            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),

              Text(
                createdAt,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),

        trailing: read
            ? null
            : const Icon(
                Icons.circle,
                color: Colors.blue,
                size: 10,
              ),

        onTap: _busy
            ? null
            : () => _openNotification(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),

        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _busy ? null : _markAllRead,
            icon: const Icon(Icons.done_all),
          ),

          IconButton(
            tooltip: 'Làm mới',
            onPressed: _busy ? null : _refresh,
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          final unreadCount = notifications
              .where((item) => !_isRead(item))
              .length;

          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),

                  Icon(
                    Icons.notifications_off_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 16),

                  Center(
                    child: Text(
                      'Bạn chưa có thông báo nào',
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_busy)
                const LinearProgressIndicator(),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chưa đọc: $unreadCount'
                    ' / ${notifications.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,

                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),

                    itemCount: notifications.length,

                    itemBuilder: (context, index) {
                      return _buildNotification(
                        notifications[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}