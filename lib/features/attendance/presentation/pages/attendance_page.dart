import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/features/attendance/presentation/bloc/attendance_cubit.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  void initState() {
    super.initState();
    // Lazy-start the all-users stream only while this page is open.
    context.read<AttendanceCubit>().startTodayMonitoring();
  }
  void _showLunchDialog(BuildContext context, {required bool isStart}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isStart ? 'Перерыв на обед' : 'Вернулся с обеда'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Комментарий (необязательно)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final note = controller.text.trim();
              if (isStart) {
                context.read<AttendanceCubit>().startLunch(note);
              } else {
                context.read<AttendanceCubit>().endLunch(note);
              }
              Navigator.pop(ctx);
            },
            child: Text(isStart ? 'Начать обед' : 'Закончить обед'),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(BuildContext context, DateTime day, List<AttendanceRecord> allRecords) {
    final c = Theme.of(context).extension<AppColors>()!;
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime(day.year, day.month, day.day));
    final userRecords = allRecords.where((r) => r.dateKey == dateKey).toList();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(DateFormat('MMM d, yyyy').format(day)),
        content: userRecords.isEmpty 
          ? const Text('Нет записей за этот день')
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final record in userRecords) ...[
                  Text('Пришёл: ${DateFormat('HH:mm').format(record.timestamp.toLocal())}', 
                      style: AppType.bodyStrong(c)),
                  if (record.lunchStart != null)
                    Text('Обед начал: ${DateFormat('HH:mm').format(record.lunchStart!.toLocal())}',
                        style: AppType.sm(c)),
                  if (record.lunchEnd != null)
                    Text('Обед кончил: ${DateFormat('HH:mm').format(record.lunchEnd!.toLocal())}',
                        style: AppType.sm(c)),
                  if (record.checkOutNote != null)
                    Text('Ушёл: ${DateFormat('HH:mm').format(record.timestamp.toLocal())}',
                        style: AppType.bodyStrong(c)),
                  const SizedBox(height: AppSpacing.s2),
                ],
              ],
            ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: c.surface,
        elevation: 0,
      ),
      body: BlocBuilder<AttendanceCubit, AttendanceState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPad),
            children: [
              _buildCalendar(c, state.myRecords, state.todayStatuses),
              const SizedBox(height: AppSpacing.s4),
              _buildActions(c, context, state),
              const SizedBox(height: AppSpacing.s4),
              _buildTodayList(c, state.todayStatuses),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(AppColors c, List<AttendanceRecord> records, List<AttendanceStatus> statuses) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendar', style: AppType.h3(c)),
          const SizedBox(height: AppSpacing.s3),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = firstOfMonth.add(Duration(days: index));
              final hasRecord = records.any((r) =>
                r.dateKey == DateFormat('yyyy-MM-dd').format(DateTime(day.year, day.month, day.day)));
              return GestureDetector(
                onTap: hasRecord ? () => _showDayDetails(context, day, records) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: hasRecord ? c.success.withValues(alpha: 0.2) : null,
                    border: Border.all(
                      color: DateUtils.isSameDay(day, now) ? c.accentSolid : c.border,
                      width: DateUtils.isSameDay(day, now) ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppType.sm(c).copyWith(
                        color: hasRecord ? c.success : c.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(AppColors c, BuildContext context, AttendanceState state) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc());
    final myTodayRecord = state.myRecords.cast<AttendanceRecord?>().firstWhere(
      (r) => r?.dateKey == todayKey,
      orElse: () => null,
    );

    // Fully done for the day (checked out).
    if (myTodayRecord != null && myTodayRecord.checkOutNote != null) {
      return AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: c.success, size: 20),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance marked', style: AppType.bodyStrong(c)),
                  Text(
                    'Arrived ${DateFormat('HH:mm').format(myTodayRecord.timestamp.toLocal())}',
                    style: AppType.sm(c),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Check-in — gradient primary button.
          if (state.canCheckIn)
            _AttendanceButton(
              onTap: state.isCheckingIn
                  ? null
                  : () => context.read<AttendanceCubit>().checkIn(),
              loading: state.isCheckingIn,
              icon: Icons.login_rounded,
              label: 'Mark attendance',
              gradient: true,
              c: c,
            ),

          // Already checked in — status row + follow-up actions.
          if (myTodayRecord != null && !state.canCheckIn) ...[
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: c.success, size: 18),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  'Arrived ${DateFormat('HH:mm').format(myTodayRecord.timestamp.toLocal())}',
                  style: AppType.bodyStrong(c).copyWith(color: c.success),
                ),
              ],
            ),
            if (state.canStartLunch) ...[
              const SizedBox(height: AppSpacing.s3),
              _AttendanceButton(
                onTap: () => _showLunchDialog(context, isStart: true),
                icon: Icons.free_breakfast_rounded,
                label: 'Start lunch break',
                c: c,
              ),
            ],
            if (state.canEndLunch) ...[
              const SizedBox(height: AppSpacing.s3),
              _AttendanceButton(
                onTap: () => _showLunchDialog(context, isStart: false),
                icon: Icons.keyboard_return_rounded,
                label: 'Back from lunch',
                c: c,
              ),
            ],
            if (state.canCheckOut) ...[
              const SizedBox(height: AppSpacing.s3),
              _AttendanceButton(
                onTap: state.isCheckingOut
                    ? null
                    : () => context.read<AttendanceCubit>().checkOut('Checked out'),
                loading: state.isCheckingOut,
                icon: Icons.logout_rounded,
                label: 'Check out',
                c: c,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTodayList(AppColors c, List<AttendanceStatus> statuses) {
    final present = statuses.where((s) => s.record != null).length;
    return AppCard.flush(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                Expanded(child: Text('$present/${statuses.length} arrived today', style: AppType.bodyStrong(c))),
                Text(DateFormat('MMM d').format(DateTime.now()), style: AppType.sm(c)),
              ],
            ),
          ),
          if (statuses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: Text('No one has checked in yet'),
            )
          else
            for (var i = 0; i < statuses.length; i++)
              _StatusRow(status: statuses[i], divider: i != statuses.length - 1),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final AttendanceStatus status;
  final bool divider;
  const _StatusRow({required this.status, required this.divider});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final record = status.record;

    String label;
    Color chipColor;
    if (record == null) {
      label = 'Не пришёл';
      chipColor = c.textDim;
    } else if (record.lunchStart != null && record.lunchEnd == null) {
      label = 'На обеде';
      chipColor = c.accentSolid;
    } else if (record.checkOutNote != null) {
      label = 'Ушёл';
      chipColor = c.textDim;
    } else {
      label = 'Пришёл';
      chipColor = c.success;
    }

    return GestureDetector(
      onTap: () => context.push('/aura/profile/${status.user.id}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        children: [
          Avatar(id: status.user.id, name: status.user.displayName, photoUrl: status.user.photoURL, size: 36),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.user.displayName, style: AppType.h3(c)),
                Text(record != null ? 'Пришёл в ${DateFormat('HH:mm').format(record.timestamp.toLocal())}' : 'Не пришёл', style: AppType.sm(c)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.rChip),
            ),
            child: Text(label, style: AppType.sm(c).copyWith(color: chipColor)),
          ),
        ],
      ),
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;
  final IconData icon;
  final String label;
  final bool gradient;
  final AppColors c;

  const _AttendanceButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.c,
    this.loading = false,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gradient ? AppGradients.aura(c) : null,
            color: gradient ? null : c.surface3,
            borderRadius: BorderRadius.circular(AppSpacing.rSm),
          ),
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gradient ? Colors.white : c.accentSolid,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: gradient ? Colors.white : c.text,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      label,
                      style: AppType.bodyStrong(c).copyWith(
                        color: gradient ? Colors.white : c.text,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
