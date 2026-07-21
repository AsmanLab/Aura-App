import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';

class UserAttendancePage extends StatefulWidget {
  final String userId;
  const UserAttendancePage({super.key, required this.userId});

  @override
  State<UserAttendancePage> createState() => _UserAttendancePageState();
}

class _UserAttendancePageState extends State<UserAttendancePage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  late final Stream<UserModel?> _userStream =
      sl<ProfileRepository>().watchUser(widget.userId);
  late final Stream<List<AttendanceRecord>> _recordsStream =
      sl<AttendanceRepository>().watchMyAttendance(widget.userId);

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(DateTime.now().year, DateTime.now().month + 1))) {
      setState(() => _month = next);
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);
  }

  void _showDetails(BuildContext context, AppColors c, AttendanceRecord r) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.rLg)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPad,
          AppSpacing.s5,
          AppSpacing.screenPad,
          AppSpacing.s8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              DateFormat('EEEE, MMMM d').format(
                DateTime.parse(r.dateKey),
              ),
              style: AppType.h3(c),
            ),
            const SizedBox(height: AppSpacing.s4),
            _DetailRow(
              icon: Icons.login,
              label: s.checkIn,
              value: DateFormat('HH:mm').format(r.timestamp.toLocal()),
              c: c,
            ),
            if (r.lunchStart != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _DetailRow(
                icon: Icons.restaurant,
                label: s.lunchStart,
                value: DateFormat('HH:mm').format(r.lunchStart!.toLocal()),
                c: c,
              ),
            ],
            if (r.lunchEnd != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _DetailRow(
                icon: Icons.restaurant_outlined,
                label: s.lunchEnd,
                value: DateFormat('HH:mm').format(r.lunchEnd!.toLocal()),
                c: c,
              ),
            ],
            if (r.checkOutNote != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _DetailRow(
                icon: Icons.logout,
                label: s.checkOut,
                value: r.checkOutNote!,
                c: c,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: StreamBuilder<UserModel?>(
        stream: _userStream,
        builder: (context, userSnap) {
          final user = userSnap.data;
          return StreamBuilder<List<AttendanceRecord>>(
            stream: _recordsStream,
            builder: (context, recordsSnap) {
              final allRecords = recordsSnap.data ?? [];
              final isRu = Localizations.localeOf(context).languageCode == 'ru';
              final prefix =
                  '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
              final monthRecords = {
                for (final r in allRecords)
                  if (r.dateKey.startsWith(prefix)) r.dateKey: r,
              };

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: c.bg,
                    surfaceTintColor: Colors.transparent,
                    foregroundColor: c.text,
                    elevation: 0,
                    expandedHeight: user == null ? kToolbarHeight : 180,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    flexibleSpace: user == null
                        ? null
                        : FlexibleSpaceBar(
                            centerTitle: true,
                            titlePadding: const EdgeInsets.only(bottom: 14),
                            title: Text(user.displayName, style: AppType.h3(c)),
                            background: SafeArea(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Avatar(
                                    id: user.id,
                                    name: user.displayName,
                                    photoUrl: user.photoURL,
                                    size: 64,
                                    ring: true,
                                  ),
                                  const SizedBox(height: AppSpacing.s2),
                                   Text(isRu ? user.role.labelRu : user.role.label, style: AppType.sm(c)),
                                  const SizedBox(height: AppSpacing.s6),
                                ],
                              ),
                            ),
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPad,
                      AppSpacing.s4,
                      AppSpacing.screenPad,
                      120,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // Month navigator
                        Row(
                          children: [
                            IconButton(
                              onPressed: _prevMonth,
                              icon: Icon(Icons.chevron_left, color: c.text),
                            ),
                            Expanded(
                              child: Text(
                                DateFormat('MMMM yyyy').format(_month),
                                textAlign: TextAlign.center,
                                style: AppType.bodyStrong(c),
                              ),
                            ),
                            IconButton(
                              onPressed: _canGoNext ? _nextMonth : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color: _canGoNext ? c.text : c.textFaint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        AppCard(
                          child: Column(
                            children: [
                              // Day-of-week headers
                              Row(
                                children: [
                                  for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          d,
                                          style: AppType.label(c),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s2),
                              _CalendarGrid(
                                month: _month,
                                records: monthRecords,
                                onDayTap: (r) => _showDetails(context, c, r),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        // Legend
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendDot(color: c.success, label: s.present, c: c),
                            const SizedBox(width: AppSpacing.s4),
                            _LegendDot(color: c.textFaint, label: s.absent, c: c),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        // Monthly summary
                        if (monthRecords.isNotEmpty) ...[
                          AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.daysPresent, style: AppType.sm(c)),
                                      const SizedBox(height: AppSpacing.s1),
                                      Text(
                                        '${monthRecords.length}',
                                        style: AppType.h2(c).copyWith(color: c.success),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.weekdaysInMonth, style: AppType.sm(c)),
                                      const SizedBox(height: AppSpacing.s1),
                                      Text(
                                        '${_weekdaysInMonth(_month)}',
                                        style: AppType.h2(c),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  int _weekdaysInMonth(DateTime month) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    var count = 0;
    for (var i = 1; i <= days; i++) {
      final d = DateTime(month.year, month.month, i);
      if (d.weekday <= DateTime.friday) count++;
    }
    return count;
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<String, AttendanceRecord> records;
  final void Function(AttendanceRecord) onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.records,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final offset = firstWeekday - 1; // cells to skip before day 1
    final totalCells = offset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Builder(builder: (context) {
                  final cell = row * 7 + col;
                  final dayNum = cell - offset + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }
                  final date = DateTime(month.year, month.month, dayNum);
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);
                  final record = records[dateKey];
                  final isWeekend = date.weekday >= DateTime.saturday;
                  final isFuture = date.isAfter(today);
                  final isToday = DateUtils.isSameDay(date, today);
                  final isPresent = record != null;

                  Color? bgColor;
                  Color textColor;
                  if (isWeekend) {
                    bgColor = null;
                    textColor = c.textFaint;
                  } else if (isFuture) {
                    bgColor = null;
                    textColor = c.textFaint;
                  } else if (isPresent) {
                    bgColor = c.success.withValues(alpha: 0.18);
                    textColor = c.success;
                  } else {
                    bgColor = c.surface3;
                    textColor = c.textDim;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: isPresent ? () => onDayTap(record) : null,
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(AppSpacing.rSm),
                          border: isToday
                              ? Border.all(color: c.accentSolid, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$dayNum',
                                style: AppType.sm(c).copyWith(
                                  color: textColor,
                                  fontWeight: isToday || isPresent
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                              if (isPresent)
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: c.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors c;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface3,
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
          ),
          child: Icon(icon, size: 18, color: c.textDim),
        ),
        const SizedBox(width: AppSpacing.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppType.sm(c)),
            Text(value, style: AppType.bodyStrong(c)),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final AppColors c;

  const _LegendDot({required this.color, required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(label, style: AppType.sm(c)),
      ],
    );
  }
}
