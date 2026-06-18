import 'package:flutter/material.dart';

import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';

/// Attendance card: calendar view similar to GitHub contributions + check-in button.
class AttendanceCalendar extends StatelessWidget {
  final List<AttendanceRecord> records;
  final VoidCallback? onCheckIn;
  final bool canCheckIn;
  final bool isCheckingIn;

  const AttendanceCalendar({
    super.key,
    required this.records,
    this.onCheckIn,
    this.canCheckIn = true,
    this.isCheckingIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    final daysWithAttendance = <DateTime, bool>{};
    for (final record in records) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      daysWithAttendance[date] = true;
    }

    final now = DateTime.now();
    final weeks = <List<DateTime>>[];

    for (var week = 0; week < 6; week++) {
      final weekDates = <DateTime>[];
      for (var day = 0; day < 7; day++) {
        final date = now.subtract(Duration(days: (5 - week) * 7 + (6 - day)));
        weekDates.add(date);
      }
      weeks.add(weekDates);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance', style: AppType.sm(c)),
          const SizedBox(height: AppSpacing.s3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildDayLabels(c),
                const SizedBox(width: AppSpacing.s2),
                for (var weekIndex = 0; weekIndex < weeks.length; weekIndex++)
                  _buildWeekColumn(weeks[weekIndex], daysWithAttendance, c),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          _buildCheckInButton(context),
        ],
      ),
    );
  }

  Widget _buildDayLabels(AppColors c) {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final label in labels)
          SizedBox(
            height: 17,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: c.textFaint),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekColumn(
    List<DateTime> days,
    Map<DateTime, bool> attendance,
    AppColors c,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var dayIndex = 0; dayIndex < 7; dayIndex++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: _getColorForDay(attendance, days[dayIndex], c),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }

  Color _getColorForDay(
    Map<DateTime, bool> attendance,
    DateTime day,
    AppColors c,
  ) {
    final hasAttendance = attendance[day] ?? false;
    return hasAttendance ? c.accentSolid : c.surface3;
  }

  Widget _buildCheckInButton(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canCheckIn && !isCheckingIn ? onCheckIn : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accentSolid,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
          ),
          disabledBackgroundColor: c.surface3,
        ),
        child: isCheckingIn
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                canCheckIn
                    ? 'Отметиться о прибытии'
                    : 'Доступно с 11:00 до 13:00 (Пн-Пт)',
                style: AppType.bodyStrong(c),
              ),
      ),
    );
  }
}
