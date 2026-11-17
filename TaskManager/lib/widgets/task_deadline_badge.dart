import 'package:flutter/material.dart';

class TaskDeadline {
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value.toLocal();
    }

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }

  static int overdueDays(
    Map<String, dynamic> task, {
    DateTime? today,
  }) {
    // Cong viec hoan thanh khong bi canh bao.
    final status =
        task['status']?.toString().toLowerCase();

    if (status == 'completed') {
      return 0;
    }

    final due = _parseDate(task['dueDate']);

    if (due == null) return 0;

    final now = today ?? DateTime.now();

    // So sanh ngay lich, khong so sanh gio.
    // Dung UTC de tranh sai lech ngay do DST.
    final currentDay = DateTime.utc(
      now.year,
      now.month,
      now.day,
    );

    final dueDay = DateTime.utc(
      due.year,
      due.month,
      due.day,
    );

    final days = currentDay.difference(
      dueDay,
    ).inDays;

    return days > 0 ? days : 0;
  }

  static bool isOverdue(
    Map<String, dynamic> task, {
    DateTime? today,
  }) {
    return overdueDays(
      task,
      today: today,
    ) > 0;
  }
}

class TaskDeadlineBadge extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskDeadlineBadge({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final days = TaskDeadline.overdueDays(task);

    if (days == 0) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade800,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Qu\u00E1 h\u1EA1n $days ng\u00E0y',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}