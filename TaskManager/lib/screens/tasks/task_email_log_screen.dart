import 'package:flutter/material.dart';
import '../../services/email_log_service.dart';

class TaskEmailLogScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskEmailLogScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskEmailLogScreen> createState() =>
      _TaskEmailLogScreenState();
}

class _TaskEmailLogScreenState
    extends State<TaskEmailLogScreen> {
  final _service = EmailLogService();

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getLogs(widget.taskId);
  }

  Future<void> _refresh() async {
    final next = _service.getLogs(widget.taskId);

    setState(() {
      _future = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder hien thi loi.
    }
  }

  String _status(dynamic value) {
    final status = (value ?? '')
        .toString()
        .toLowerCase();

    switch (status) {
      case 'sent':
        return '\u0110\u00E3 g\u1EEDi';
      case 'failed':
        return 'Th\u1EA5t b\u1EA1i';
      case 'pending':
        return '\u0110ang ch\u1EDD';
      default:
        return 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh';
    }
  }

  Color _statusColor(dynamic value) {
    switch ((value ?? '').toString().toLowerCase()) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _date(dynamic value) {
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

  Widget _emailCard(Map<String, dynamic> log) {
    final status = log['status'];

    final subject = (
      log['subject'] ??
      'Th\u00F4ng b\u00E1o email'
    ).toString();

    final recipient = (
      log['recipientEmail'] ??
      log['email'] ??
      ''
    ).toString();

    final eventType = (
      log['eventType'] ?? ''
    ).toString();

    final error = (
      log['errorMessage'] ?? ''
    ).toString();

    final attempts = (
      log['attempts'] ?? 0
    ).toString();

    final sentAt = _date(log['sentAt']);
    final createdAt = _date(log['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mail_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _statusColor(status)
                    .withValues(alpha: 0.12),
              ),
              child: Text(
                _status(status),
                style: TextStyle(
                  color: _statusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (recipient.isNotEmpty)
              Text(
                'Ng\u01B0\u1EDDi nh\u1EADn: $recipient',
              ),

            if (eventType.isNotEmpty)
              Text(
                'S\u1EF1 ki\u1EC7n: $eventType',
              ),

            Text(
              'S\u1ED1 l\u1EA7n th\u1EED g\u1EEDi: $attempts',
            ),

            if (createdAt.isNotEmpty)
              Text(
                'T\u1EA1o l\u00FAc: $createdAt',
              ),

            if (sentAt.isNotEmpty)
              Text(
                'G\u1EEDi l\u00FAc: $sentAt',
              ),

            if (error.isNotEmpty) ...[
              const Divider(),
              Text(
                'L\u1ED7i: $error',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
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
          'L\u1ECBch s\u1EED g\u1EEDi email',
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text(
                        'Th\u1EED l\u1EA1i',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final logs = snapshot.data ?? [];

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

                const SizedBox(height: 16),

                Text(
                  'T\u1ED5ng s\u1ED1 email: ${logs.length}',
                ),

                const SizedBox(height: 20),

                if (logs.isEmpty) ...[
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Ch\u01B0a c\u00F3 l\u1ECBch s\u1EED g\u1EEDi email',
                    ),
                  ),
                ] else
                  ...logs.map(_emailCard),
              ],
            ),
          );
        },
      ),
    );
  }
}