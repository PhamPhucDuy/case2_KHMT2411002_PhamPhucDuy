import 'package:flutter/material.dart';

import '../../services/task_service.dart';
import 'task_detail_screen.dart';

class TaskSearchScreen extends StatefulWidget {
  const TaskSearchScreen({super.key});

  @override
  State<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends State<TaskSearchScreen> {
  final TaskService _service = TaskService();
  final TextEditingController _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _future;

  String _status = '';
  String _priority = '';
  String _sort = 'due';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _search.addListener(_changed);
  }

  @override
  void dispose() {
    _search.removeListener(_changed);
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<List<Map<String, dynamic>>> _load() async {
    dynamic data = await _service.getTasks();
    for (var i = 0; i < 5; i++) {
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      if (data is Map) {
        data =
            data['tasks'] ?? data['data'] ?? data['results'] ?? data['items'];
      } else {
        break;
      }
    }
    throw const FormatException(
      'D\u1EEF li\u1EC7u c\u00F4ng vi\u1EC7c kh\u00F4ng h\u1EE3p l\u1EC7',
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // FutureBuilder hien thi loi tai giao dien.
    }
  }

  String _value(dynamic value) => value?.toString().trim() ?? '';
  String _field(Map<String, dynamic> task, List<String> names) {
    for (final name in names) {
      final value = _value(task[name]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  // Tim ten tieng Viet co hoac khong co dau.
  String _normalize(String value) {
    var result = value.toLowerCase();
    const groups = <String, String>{
      'a': '\u00E0\u00E1\u1EA1\u1EA3\u00E3\u00E2\u1EA7\u1EA5\u1EAD\u1EA9\u1EAB\u0103\u1EB1\u1EAF\u1EB7\u1EB3\u1EB5',
      'e': '\u00E8\u00E9\u1EB9\u1EBB\u1EBD\u00EA\u1EC1\u1EBF\u1EC7\u1EC3\u1EC5',
      'i': '\u00EC\u00ED\u1ECB\u1EC9\u0129',
      'o': '\u00F2\u00F3\u1ECD\u1ECF\u00F5\u00F4\u1ED3\u1ED1\u1ED9\u1ED5\u1ED7\u01A1\u1EDD\u1EDB\u1EE3\u1EDF\u1EE1',
      'u': '\u00F9\u00FA\u1EE5\u1EE7\u0169\u01B0\u1EEB\u1EE9\u1EF1\u1EED\u1EEF',
      'y': '\u1EF3\u00FD\u1EF5\u1EF7\u1EF9',
      'd': '\u0111',
    };
    for (final entry in groups.entries) {
      for (final accent in entry.value.split('')) {
        result = result.replaceAll(accent, entry.key);
      }
    }
    return result.trim();
  }

  DateTime? _date(Map<String, dynamic> task, List<String> fields) {
    for (final field in fields) {
      final raw = _value(task[field]);
      if (raw.isEmpty) continue;
      final date = DateTime.tryParse(raw);
      if (date != null) return date;
    }
    return null;
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'Ch\u01B0a c\u00F3';
    final d = date.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  int _compareDates(DateTime? a, DateTime? b, {bool descending = false}) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return descending ? b.compareTo(a) : a.compareTo(b);
  }

  int _priorityRank(String value) {
    switch (_normalize(value)) {
      case 'urgent':
      case 'critical':
      case 'khan cap':
        return 4;
      case 'high':
      case 'cao':
        return 3;
      case 'medium':
      case 'normal':
      case 'trung binh':
        return 2;
      case 'low':
      case 'thap':
        return 1;
      default:
        return 0;
    }
  }

  String _statusLabel(String value) {
    switch (value.toLowerCase()) {
      case 'todo':
      case 'to_do':
      case 'pending':
      case 'not_started':
        return 'Ch\u01B0a th\u1EF1c hi\u1EC7n';
      case 'in_progress':
      case 'doing':
      case 'processing':
        return '\u0110ang th\u1EF1c hi\u1EC7n';
      case 'done':
      case 'completed':
        return 'Ho\u00E0n th\u00E0nh';
      default:
        return value;
    }
  }

  String _priorityLabel(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung b\u00ECnh';
      case 'low':
        return 'Th\u1EA5p';
      case 'urgent':
        return 'Kh\u1EA9n c\u1EA5p';
      default:
        return value;
    }
  }

  List<Map<String, dynamic>> _filtered(
    List<Map<String, dynamic>> all, {
    String? status,
    String? priority,
  }) {
    final selectedStatus = status ?? _status;
    final selectedPriority = priority ?? _priority;
    final query = _normalize(_search.text);
    final result = all.where((task) {
      final title = _field(task, ['title', 'name']);
      final description = _field(task, ['description', 'content']);
      final status = _field(task, ['status']);
      final priority = _field(task, ['priority']);
      final matchesSearch =
          query.isEmpty || _normalize('$title $description').contains(query);
      return matchesSearch &&
          (selectedStatus.isEmpty || selectedStatus == status) &&
          (selectedPriority.isEmpty || selectedPriority == priority);
    }).toList();

    switch (_sort) {
      case 'newest':
        result.sort(
          (a, b) => _compareDates(
            _date(a, ['createdAt', 'created_at']),
            _date(b, ['createdAt', 'created_at']),
            descending: true,
          ),
        );
        break;
      case 'oldest':
        result.sort(
          (a, b) => _compareDates(
            _date(a, ['createdAt', 'created_at']),
            _date(b, ['createdAt', 'created_at']),
          ),
        );
        break;
      case 'priority':
        result.sort((a, b) {
          final rank = _priorityRank(_field(b, ['priority']))
              .compareTo(_priorityRank(_field(a, ['priority'])));
          return rank != 0
              ? rank
              : _compareDates(
                  _date(a, ['dueDate', 'deadline', 'dueAt']),
                  _date(b, ['dueDate', 'deadline', 'dueAt']),
                );
        });
        break;
      case 'title':
        result.sort(
          (a, b) =>
              _normalize(_field(a, ['title', 'name']))
                  .compareTo(_normalize(_field(b, ['title', 'name']))),
        );
        break;
      default:
        result.sort(
          (a, b) => _compareDates(
            _date(a, ['dueDate', 'deadline', 'dueAt']),
            _date(b, ['dueDate', 'deadline', 'dueAt']),
          ),
        );
    }
    return result;
  }

  void _reset() {
    _search.clear();
    setState(() {
      _status = '';
      _priority = '';
      _sort = 'due';
    });
  }

  Future<void> _openTask(Map<String, dynamic> task) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (!mounted) return;
    await _refresh();
  }

  Widget _buildTask(Map<String, dynamic> task) {
    final title = _field(task, ['title', 'name']);
    final status = _field(task, ['status']);
    final priority = _field(task, ['priority']);
    final due = _date(task, ['dueDate', 'deadline', 'dueAt']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.task_alt_outlined),
        title: Text(title.isEmpty ? 'C\u00F4ng vi\u1EC7c' : title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'Tr\u1EA1ng th\u00E1i: ${status.isEmpty ? "Ch\u01B0a r\u00F5" : _statusLabel(status)}\n'
            '\u01AFu ti\u00EAn: ${priority.isEmpty ? "Ch\u01B0a r\u00F5" : _priorityLabel(priority)}'
            '  \u00B7  H\u1EA1n: ${_dateText(due)}',
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openTask(task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('T\u00ECm ki\u1EBFm c\u00F4ng vi\u1EC7c'),
        actions: [
          IconButton(
            tooltip: 'L\u00E0m m\u1EDBi d\u1EEF li\u1EC7u',
            onPressed: _refresh,
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
                padding: const EdgeInsets.all(18),
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

          final tasks = snapshot.data ?? [];
          final statuses =
              tasks
                  .map((task) => _field(task, ['status']))
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final priorities =
              tasks
                  .map((task) => _field(task, ['priority']))
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final activeStatus = statuses.contains(_status) ? _status : '';
          final activePriority = priorities.contains(_priority)
              ? _priority
              : '';
          final visible = _filtered(
            tasks,
            status: activeStatus,
            priority: activePriority,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    labelText:
                        'T\u00ECm theo t\u00EAn ho\u1EB7c m\u00F4 t\u1EA3',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _search.clear,
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('status-$activeStatus'),
                        initialValue: activeStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Tr\u1EA1ng th\u00E1i',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('T\u1EA5t c\u1EA3'),
                          ),
                          for (final value in statuses)
                            DropdownMenuItem(
                              value: value,
                              child: Text(
                                _statusLabel(value),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _status = value ?? '';
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('priority-$activePriority'),
                        initialValue: activePriority,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: '\u01AFu ti\u00EAn',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('T\u1EA5t c\u1EA3'),
                          ),
                          for (final value in priorities)
                            DropdownMenuItem(
                              value: value,
                              child: Text(
                                _priorityLabel(value),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _priority = value ?? '';
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'S\u1EAFp x\u1EBFp',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'due',
                      child: Text('H\u1EA1n g\u1EA7n nh\u1EA5t'),
                    ),
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('M\u1EDBi t\u1EA1o nh\u1EA5t'),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text('C\u0169 nh\u1EA5t'),
                    ),
                    DropdownMenuItem(
                      value: 'priority',
                      child: Text('\u01AFu ti\u00EAn cao nh\u1EA5t'),
                    ),
                    DropdownMenuItem(
                      value: 'title',
                      child: Text('T\u00EAn A - Z'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _sort = value ?? 'due';
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hi\u1EC3n th\u1ECB ${visible.length}/${tasks.length} c\u00F4ng vi\u1EC7c',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('X\u00F3a b\u1ED9 l\u1ECDc'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 70),
                    child: Center(
                      child: Text(
                        'Kh\u00F4ng c\u00F3 c\u00F4ng vi\u1EC7c ph\u00F9 h\u1EE3p',
                      ),
                    ),
                  )
                else
                  for (final task in visible) _buildTask(task),
              ],
            ),
          );
        },
      ),
    );
  }
}
