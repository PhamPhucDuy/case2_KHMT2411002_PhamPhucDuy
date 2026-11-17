import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_list_screen.dart';
import '../../theme/app_theme.dart';
import '../dashboard/task_dashboard_screen.dart';

// CASE2_MODERN_STATS_V2
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = StatisticsService();
  late Future<List<Map<String, dynamic>>> _future;

  static const Color _blue = Color(0xFF4767E8);
  static const Color _mint = Color(0xFF13A78F);
  static const Color _amber = Color(0xFFF1A53A);
  static const Color _red = Color(0xFFE05B61);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() => Future.wait([
    _service.getTaskStats(),
    _service.getAssignmentStats(),
    _service.getDeadlineStats(),
  ]);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by FutureBuilder.
    }
  }

  Future<void> _openTasks() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const TaskListScreen()));
    if (mounted) await _refresh();
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NotificationScreen()));
    if (mounted) await _refresh();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onMenu(String value) {
    switch (value) {
      case 'profile':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
        break;
      case 'refresh':
        _refresh();
        break;
      case 'logout':
        _logout();
        break;
      case 'theme':
        AppThemeController.instance.toggle();
        break;
      case 'dashboard':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TaskDashboardScreen()),
        );
        break;
    }
  }

  int _count(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is List) return value.length;
    if (value is Map) {
      return _count(value['count'] ?? value['total'] ?? 0);
    }
    return 0;
  }

  Map<String, int> _statusCounts(dynamic source) {
    final result = <String, int>{'todo': 0, 'in_progress': 0, 'completed': 0};
    if (source is Map) {
      for (final entry in source.entries) {
        final key = entry.key.toString().toLowerCase();
        if (result.containsKey(key)) result[key] = _count(entry.value);
      }
    } else if (source is List) {
      for (final entry in source) {
        if (entry is! Map) continue;
        final key = (entry['status'] ?? entry['_id'] ?? '')
            .toString()
            .toLowerCase();
        if (result.containsKey(key)) {
          result[key] = _count(entry['count'] ?? entry);
        }
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _taskItems(dynamic source) {
    final items = source is Map ? source['tasks'] : source;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _date(dynamic source) {
    final raw = source?.toString() ?? '';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Widget _surface({required Widget child, EdgeInsets? padding}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeading(String title, {String? subtitle}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _hero(int completed, int total) {
    final rate = total == 0 ? 0 : ((completed / total) * 100).round();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF253E9F), Color(0xFF526DE4), Color(0xFF3894D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -46,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFFFE59E),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'KH\u00D4NG GIAN L\u00C0M VI\u1EC6C',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Qu\u1EA3n l\u00FD c\u00F4ng vi\u1EC7c\nth\u00F4ng minh h\u01A1n',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  'Theo d\u00F5i m\u1EE5c ti\u00EAu v\u00E0 ti\u1EBFn \u0111\u1ED9 c\u1EE7a c\u1EA3 nh\u00F3m.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .24),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$rate% ho\u00E0n th\u00E0nh',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _openTasks,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Xem vi\u1EC7c',
                                style: TextStyle(
                                  color: Color(0xFF3046A4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF3046A4),
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String title,
    int value,
    String hint,
    IconData icon,
    Color accent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: _surface(
        padding: const EdgeInsets.all(15),
        child: SizedBox(
          height: 123,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 21),
                  ),
                  const Spacer(),
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLine(String label, int value, int total, Color color) {
    final scheme = Theme.of(context).colorScheme;
    final double rate = total <= 0
        ? 0.0
        : (value / total).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$value',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: .12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressPanel(int total, int completed, Map<String, int> status) {
    final scheme = Theme.of(context).colorScheme;
    final percent = total <= 0 ? 0 : ((completed / total) * 100).round();
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'Ti\u1EBFn \u0111\u1ED9 c\u00F4ng vi\u1EC7c',
            subtitle: 'Ph\u00E2n b\u1ED5 c\u00E1c tr\u1EA1ng th\u00E1i hi\u1EC7n t\u1EA1i',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: total == 0 ? 0.0 : completed / total,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      backgroundColor: _blue.withValues(alpha: .11),
                      valueColor: const AlwaysStoppedAnimation(_blue),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'ho\u00E0n th\u00E0nh',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed / $total',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'c\u00F4ng vi\u1EC7c \u0111\u00E3 ho\u00E0n th\u00E0nh',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _mint.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'C\u00F9ng gi\u1EEF nh\u1ECBp ti\u1EBFn \u0111\u1ED9!',
                        style: TextStyle(
                          color: _mint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          _statusLine(
            'Ch\u01B0a th\u1EF1c hi\u1EC7n',
            status['todo'] ?? 0,
            total,
            _amber,
          ),
          _statusLine(
            '\u0110ang th\u1EF1c hi\u1EC7n',
            status['in_progress'] ?? 0,
            total,
            _blue,
          ),
          _statusLine(
            'Ho\u00E0n th\u00E0nh',
            status['completed'] ?? 0,
            total,
            _mint,
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, int value, IconData icon, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _activityPanel(Map role, Map<String, dynamic> assignment) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            'L\u00E0m vi\u1EC7c nh\u00F3m',
            subtitle:
                'Vai tr\u00F2 v\u00E0 ho\u1EA1t \u0111\u1ED9ng giao vi\u1EC7c',
          ),
          const SizedBox(height: 18),
          _miniInfo(
            'T\u00F4i \u0111\u00E3 t\u1EA1o',
            _count(role['created']),
            Icons.edit_note_rounded,
            _blue,
          ),
          const SizedBox(height: 14),
          _miniInfo(
            '\u0110\u01B0\u1EE3c giao cho t\u00F4i',
            _count(role['assigned']),
            Icons.assignment_ind_outlined,
            _mint,
          ),
          const SizedBox(height: 14),
          _miniInfo(
            '\u0110\u01B0\u1EE3c chia s\u1EBB',
            _count(role['shared']),
            Icons.people_alt_outlined,
            _amber,
          ),
          const Divider(height: 28),
          _miniInfo(
            'T\u00F4i ph\u1EE5 tr\u00E1ch ch\u00EDnh',
            _count(assignment['primaryAssignee']),
            Icons.star_border_rounded,
            _blue,
          ),
          const SizedBox(height: 14),
          _miniInfo(
            'T\u00F4i giao cho ng\u01B0\u1EDDi kh\u00E1c',
            _count(assignment['assignedByMe']),
            Icons.send_outlined,
            _mint,
          ),
        ],
      ),
    );
  }

  Widget _deadlinePanel(dynamic overdue, dynamic soon, int days) {
    final overdueCount = _count(overdue);
    final soonCount = _count(soon);
    final overdueTasks = _taskItems(overdue);
    final soonTasks = _taskItems(soon);
    final scheme = Theme.of(context).colorScheme;
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeading(
                  'C\u1EA7n ch\u00FA \u00FD',
                  subtitle: 'Th\u1EDDi h\u1EA1n v\u00E0 nhi\u1EC7m v\u1EE5 \u01B0u ti\u00EAn',
                ),
              ),
              Icon(
                Icons.event_note_outlined,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _deadlineCount(
                  count: overdueCount,
                  label: 'Qu\u00E1 h\u1EA1n',
                  icon: Icons.warning_amber_rounded,
                  color: _red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _deadlineCount(
                  count: soonCount,
                  label: 'S\u1EAFp \u0111\u1EBFn h\u1EA1n',
                  icon: Icons.schedule_rounded,
                  color: _amber,
                ),
              ),
            ],
          ),
          if (overdueTasks.isNotEmpty || soonTasks.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...overdueTasks.take(3).map((task) => _deadlineTask(task, true)),
            ...soonTasks.take(3).map((task) => _deadlineTask(task, false)),
          ] else ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: _mint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kh\u00F4ng c\u00F3 nhi\u1EC7m v\u1EE5 c\u1EA7n ch\u00FA \u00FD trong $days ng\u00E0y t\u1EDBi.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _deadlineCount({
    required int count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: .09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _deadlineTask(Map<String, dynamic> task, bool overdue) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _openTasks,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  overdue
                      ? Icons.error_outline_rounded
                      : Icons.calendar_today_outlined,
                  color: overdue ? _red : _amber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (task['title'] ?? 'C\u00F4ng vi\u1EC7c').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'H\u1EA1n: ${_date(task['dueDate'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'T\u1ED5ng quan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Th\u00F4ng b\u00E1o',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: _openNotifications,
          ),
          IconButton(
            tooltip: 'Danh s\u00E1ch c\u00F4ng vi\u1EC7c',
            icon: const Icon(Icons.view_list_rounded),
            onPressed: _openTasks,
          ),
          PopupMenuButton<String>(
            tooltip: 'T\u00F9y ch\u1ECDn',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _onMenu,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('H\u1ED3 s\u01A1 c\u00E1 nh\u00E2n'),
                ),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.brightness_6_outlined),
                  title: Text('Giao di\u1EC7n s\u00E1ng / t\u1ED1i'),
                ),
              ),
              const PopupMenuItem(
                value: 'dashboard',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.dashboard_outlined),
                  title: Text('Dashboard chi ti\u1EBFt'),
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('L\u00E0m m\u1EDBi'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.logout_rounded),
                  title: Text('\u0110\u0103ng xu\u1EA5t'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      color: scheme.error,
                      size: 44,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ch\u01B0a t\u1EA3i \u0111\u01B0\u1EE3c s\u1ED1 li\u1EC7u',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Th\u1EED l\u1EA1i'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final tasks = data[0];
          final assignment = data[1];
          final deadline = data[2];
          final statuses = _statusCounts(tasks['byStatus']);
          final inferredTotal = statuses.values.fold<int>(0, (a, b) => a + b);
          final total = tasks.containsKey('total')
              ? _count(tasks['total'])
              : inferredTotal;
          final completed = statuses['completed'] ?? 0;
          final inProgress = statuses['in_progress'] ?? 0;
          final overdue = deadline['overdue'];
          final dueSoon = deadline['dueSoon'];
          final role = tasks['byRole'] is Map ? tasks['byRole'] as Map : {};
          final days = _count(deadline['days']) > 0
              ? _count(deadline['days'])
              : 3;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              children: [
                _hero(completed, total),
                const SizedBox(height: 22),
                _sectionHeading(
                  'T\u00ECnh h\u00ECnh h\u00F4m nay',
                  subtitle:
                      'C\u00E1c ch\u1EC9 s\u1ED1 ch\u00EDnh c\u1EE7a b\u1EA1n',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _metric(
                      'T\u1ED5ng c\u00F4ng vi\u1EC7c',
                      total,
                      'Trong h\u1EC7 th\u1ED1ng',
                      Icons.inventory_2_outlined,
                      _blue,
                    ),
                    const SizedBox(width: 10),
                    _metric(
                      'Ho\u00E0n th\u00E0nh',
                      completed,
                      '\u0110\u00E3 x\u1EED l\u00FD xong',
                      Icons.task_alt_rounded,
                      _mint,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metric(
                      '\u0110ang th\u1EF1c hi\u1EC7n',
                      inProgress,
                      '\u0110ang x\u1EED l\u00FD',
                      Icons.bolt_rounded,
                      _amber,
                    ),
                    const SizedBox(width: 10),
                    _metric(
                      'Qu\u00E1 h\u1EA1n',
                      _count(overdue),
                      'C\u1EA7n \u01B0u ti\u00EAn',
                      Icons.warning_amber_rounded,
                      _red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _progressPanel(total, completed, statuses),
                const SizedBox(height: 16),
                _deadlinePanel(overdue, dueSoon, days),
                const SizedBox(height: 16),
                _activityPanel(role, assignment),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _openTasks,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'M\u1EDF danh s\u00E1ch c\u00F4ng vi\u1EC7c',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
