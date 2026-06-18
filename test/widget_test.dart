import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/core/widgets/attendance_calendar.dart';

void main() {
  testWidgets('Attendance calendar smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AttendanceCalendar(records: [], canCheckIn: false),
        ),
      ),
    );

    expect(find.byType(AttendanceCalendar), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Доступно с 11:00 до 13:00 (Пн-Пт)'), findsOneWidget);
  });
}
