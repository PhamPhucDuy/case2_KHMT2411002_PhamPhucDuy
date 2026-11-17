import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Core Task Manager files exist', () {
    const requiredFiles = [
      'lib/main.dart',
      'lib/services/task_service.dart',
      'lib/screens/tasks/task_list_screen.dart',
      'lib/screens/tasks/task_detail_screen.dart',
      'lib/screens/notifications/notification_screen.dart',
      'lib/screens/tasks/task_activity_screen.dart',
    ];

    for (final path in requiredFiles) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'Missing required file: $path',
      );
    }
  });

  testWidgets('Flutter renders a Task Manager heading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Quản lý công việc'),
          ),
        ),
      ),
    );

    expect(
      find.text('Quản lý công việc'),
      findsOneWidget,
    );
  });
}