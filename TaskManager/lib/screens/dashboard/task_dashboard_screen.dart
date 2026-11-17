import 'package:flutter/material.dart';
import '../../services/task_service.dart';
import '../tasks/task_detail_screen.dart';

class DashboardMetrics {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;
  final int overdue;
  final int dueSoon;
  final int highPriority;

  const DashboardMetrics({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
    required this.overdue,
    required this.dueSoon,
    required this.highPriority,
  });

  double get completionRate => total == 0 ? 0 : completed / total;

  static String status(Map<String, dynamic> task) =>
      (task['status'] ?? 'todo').toString().trim().toLowerCase();

  static bool isDone(Map<String, dynamic> task) {
    final value = status(task);
    return value == 'completed' || value == 'done' ||
        value == 'finished';
  }

  static DateTime? dueDate(Map<String, dynamic> task) {
    final value = task['dueDate'];
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static int? daysUntil(Map<String, dynamic> task, DateTime now) {
    final date = dueDate(task);
    if (date == null) return null;
    // Compare calendar dates, without time-of-day or DST rounding.
    final today = DateTime.utc(now.year, now.month, now.day);
    final due = DateTime.utc(date.year, date.month, date.day);
    return due.difference(today).inDays;
  }

  factory DashboardMetrics.fromTasks(
    List<Map<String, dynamic>> tasks,
    DateTime now,
  ) {
    var completed = 0;
    var inProgress = 0;
    var pending = 0;
    var overdue = 0;
    var dueSoon = 0;
    var high = 0;

    for (final task in tasks) {
      final done = isDone(task);
      final statusValue = status(task);
      if (done) {
        completed++;
      } else if (statusValue == 'in_progress' ||
          statusValue == 'doing' || statusValue == 'inprogress') {
        inProgress++;
      } else {
        pending++;
      }

      if ((task['priority'] ?? '').toString().toLowerCase() == 'high') {
        high++;
      }

      if (!done) {
        final days = daysUntil(task, now);
        if (days != null && days < 0) overdue++;
        if (days != null && days >= 0 && days <= 7) dueSoon++;
      }
    }

    return DashboardMetrics(
      total: tasks.length,
      completed: completed,
      inProgress: inProgress,
      pending: pending,
      overdue: overdue,
      dueSoon: dueSoon,
      highPriority: high,
    );
  }
}

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key});

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  final TaskService _service = TaskService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getTasks();
  }

  Future<void> _refresh() async {
    final next = _service.getTasks();
    setState(() { _future = next; });
    try {
      await next;
    } catch (_) {
      // FutureBuilder shows the error.
    }
  }

  String _dateLabel(Map<String, dynamic> task) {
    final date = DashboardMetrics.dueDate(task);
    if (date == null) return '\u0110ang c\u1EADp nh\u1EADt h\u1EA1n';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(value,
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _statusBar(String label, int value, int total, Color color) {
    final rate = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text('$value')],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: rate,
            minHeight: 9,
            borderRadius: BorderRadius.circular(8),
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _taskTile(Map<String, dynamic> task, DateTime today) {
    final days = DashboardMetrics.daysUntil(task, today);
    final overdue = days != null && days < 0;
    final dueLabel = overdue
        ? '\u0110\u00E3 qu\u00E1 h\u1EA1n ${-days} ng\u00E0y'
        : days == 0
            ? '\u0110\u1EBFn h\u1EA1n h\u00F4m nay'
            : 'H\u1EA1n: ${_dateLabel(task)}';
    final title = (task['title'] ?? 'C\u00F4ng vi\u1EC7c').toString();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: overdue
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(overdue ? Icons.warning_amber_rounded
              : Icons.event_outlined),
        ),
        title: Text(title, maxLines: 2,
          overflow: TextOverflow.ellipsis),
        subtitle: Text(dueLabel,
          style: TextStyle(
            color: overdue ? Theme.of(context).colorScheme.error : null,
            fontWeight: overdue ? FontWeight.w600 : null,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          );
          if (mounted) await _refresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'L\u00E0m m\u1EDBi',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _refresh,
                      child: const Text('Th\u1EED l\u1EA1i')),
                  ],
                ),
              ),
            );
          }

          final tasks = snapshot.data ?? <Map<String, dynamic>>[];
          final now = DateTime.now();
          final metrics = DashboardMetrics.fromTasks(tasks, now);
          final attention = tasks.where((task) {
            final days = DashboardMetrics.daysUntil(task, now);
            return !DashboardMetrics.isDone(task) &&
                days != null && days <= 7;
          }).toList()
            ..sort((a, b) =>
              (DashboardMetrics.daysUntil(a, now) ?? 999999)
                .compareTo(DashboardMetrics.daysUntil(b, now) ?? 999999));

          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = ((constraints.maxWidth - 44) / 2)
                    .clamp(140.0, 240.0).toDouble();
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('T\u1ED5ng quan c\u00F4ng vi\u1EC7c',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('D\u1EEF li\u1EC7u c\u00F4ng vi\u1EC7c t\u00E0i kho\u1EA3n c\u00F3 quy\u1EC1n xem',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(width: tileWidth,
                          child: _summaryCard(label: 'T\u1ED5ng c\u00F4ng vi\u1EC7c',
                            value: '${metrics.total}',
                            icon: Icons.assignment_outlined,
                            color: scheme.primary)),
                        SizedBox(width: tileWidth,
                          child: _summaryCard(label: '\u0110\u00E3 ho\u00E0n th\u00E0nh',
                            value: '${metrics.completed}',
                            icon: Icons.task_alt, color: Colors.green)),
                        SizedBox(width: tileWidth,
                          child: _summaryCard(label: 'Qu\u00E1 h\u1EA1n',
                            value: '${metrics.overdue}',
                            icon: Icons.warning_amber_rounded,
                            color: scheme.error)),
                        SizedBox(width: tileWidth,
                          child: _summaryCard(label: 'S\u1EAFp \u0111\u1EBFn h\u1EA1n (7 ng\u00E0y)',
                            value: '${metrics.dueSoon}',
                            icon: Icons.event_available,
                            color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ti\u1EBFn \u0111\u1ED9 chung',
                              style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Text('${(metrics.completionRate * 100).round()}%',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: metrics.completionRate,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 8),
                            Text('${metrics.completed}/${metrics.total} c\u00F4ng vi\u1EC7c ho\u00E0n th\u00E0nh'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ph\u00E2n b\u1ED5 tr\u1EA1ng th\u00E1i',
                              style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 20),
                            _statusBar('Ch\u01B0a th\u1EF1c hi\u1EC7n',
                              metrics.pending, metrics.total, Colors.blueGrey),
                            _statusBar('\u0110ang th\u1EF1c hi\u1EC7n',
                              metrics.inProgress, metrics.total, Colors.orange),
                            _statusBar('Ho\u00E0n th\u00E0nh',
                              metrics.completed, metrics.total, Colors.green),
                            Text('C\u00F4ng vi\u1EC7c \u01B0u ti\u00EAn cao: ${metrics.highPriority}',
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('C\u00F4ng vi\u1EC7c c\u1EA7n ch\u00FA \u00FD',
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (attention.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Kh\u00F4ng c\u00F3 c\u00F4ng vi\u1EC7c qu\u00E1 h\u1EA1n ho\u1EB7c s\u1EAFp \u0111\u1EBFn h\u1EA1n.'),
                        ),
                      )
                    else
                      for (final task in attention.take(6))
                        _taskTile(task, now),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}