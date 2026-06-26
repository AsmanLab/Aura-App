import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';

/// Self-contained month calendar showing attendance.
/// Manages its own month navigation state. Parent just passes [records].
class AttendanceMonthCalendar extends StatefulWidget {
  final List<AttendanceRecord> records;

  /// Called when a day with an attendance record is tapped.
  final void Function(AttendanceRecord record)? onDayTap;

  const AttendanceMonthCalendar({
    super.key,
    required this.records,
    this.onDayTap,
  });

  @override
  State<AttendanceMonthCalendar> createState() =>
      _AttendanceMonthCalendarState();
}

class _AttendanceMonthCalendarState extends State<AttendanceMonthCalendar> {
  late DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final prefix =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final monthMap = <String, AttendanceRecord>{
      for (final r in widget.records)
        if (r.dateKey.startsWith(prefix)) r.dateKey: r,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
                child: Icon(Icons.chevron_left, color: c.text, size: 22),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(_month),
                  textAlign: TextAlign.center,
                  style: AppType.bodyStrong(c),
                ),
              ),
              GestureDetector(
                onTap: _canGoNext
                    ? () => setState(
                          () => _month =
                              DateTime(_month.year, _month.month + 1),
                        )
                    : null,
                child: Icon(
                  Icons.chevron_right,
                  color: _canGoNext ? c.text : c.textFaint,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          // Weekday headers
          Row(
            children: [
              for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(d, style: AppType.label(c)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          // Day grid
          _MonthGrid(
            month: _month,
            records: monthMap,
            onDayTap: widget.onDayTap,
          ),
          const SizedBox(height: AppSpacing.s3),
          // Legend
          Row(
            children: [
              _Dot(color: c.success),
              const SizedBox(width: AppSpacing.s1),
              Text('Present', style: AppType.sm(c)),
              const SizedBox(width: AppSpacing.s4),
              _Dot(color: c.surface3),
              const SizedBox(width: AppSpacing.s1),
              Text('Absent', style: AppType.sm(c)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, AttendanceRecord> records;
  final void Function(AttendanceRecord)? onDayTap;

  const _MonthGrid({
    required this.month,
    required this.records,
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = DateTime(month.year, month.month, 1).weekday - 1;
    final rows = ((offset + daysInMonth) / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Builder(builder: (context) {
                  final dayNum = row * 7 + col - offset + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }
                  final date = DateTime(month.year, month.month, dayNum);
                  final key = DateFormat('yyyy-MM-dd').format(date);
                  final record = records[key];
                  final isWeekend = date.weekday >= DateTime.saturday;
                  final isFuture = date.isAfter(today);
                  final isToday = DateUtils.isSameDay(date, today);
                  final isPresent = record != null;

                  final Color? bg = isWeekend || isFuture
                      ? null
                      : isPresent
                          ? c.success.withValues(alpha: 0.18)
                          : c.surface3;
                  final Color fg = isPresent
                      ? c.success
                      : (isWeekend || isFuture)
                          ? c.textFaint
                          : c.textDim;

                  return Expanded(
                    child: GestureDetector(
                      onTap: (isPresent && onDayTap != null)
                          ? () => onDayTap!(record)
                          : null,
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.rSm),
                          border: isToday
                              ? Border.all(color: c.accentSolid, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: AppType.sm(c).copyWith(
                              color: fg,
                              fontWeight:
                                  (isToday || isPresent) ? FontWeight.bold : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
