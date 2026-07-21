import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/hearts_status.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final me = sl<AuthRepository>().currentUser;
    final uid = me?.id;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.accentSolid,
          backgroundColor: c.surface,
          onRefresh: () async {
            if (uid != null) await sl<ProfileRepository>().getHistory(uid);
          },
          child: BlocListener<AttendanceCubit, AttendanceState>(
            listenWhen: (prev, curr) =>
                prev.error != curr.error && curr.error != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            },
            child: StreamBuilder<UserModel?>(
              stream: uid == null
                  ? const Stream.empty()
                  : sl<ProfileRepository>().watchUser(uid),
              builder: (context, userSnap) {
                final user = userSnap.data;
                final displayName = user?.displayName ?? me?.displayName ?? '';
                final firstName = displayName.trim().isEmpty
                    ? 'there'
                    : displayName.split(' ').first;
                final isIntern = user?.role == Role.intern;
                return StreamBuilder<List<AuraTransaction>>(
                  stream: uid == null
                      ? const Stream.empty()
                      : sl<ProfileRepository>().watchHistory(uid),
                  builder: (context, snap) {
                    final loading =
                        snap.connectionState == ConnectionState.waiting;
                    final history = snap.data ?? const <AuraTransaction>[];
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPad,
                        AppSpacing.s4,
                        AppSpacing.screenPad,
                        120,
                      ),
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d').format(DateTime.now()),
                              style: AppType.sm(c),
                            ),
                            Text(s.greeting(firstName), style: AppType.h1(c)),
                          ],
                        ),
                        if (user != null) ...[
                          const SizedBox(height: AppSpacing.s4),
                          _AttendanceHomeCard(),
                          if (isIntern) ...[
                            const SizedBox(height: AppSpacing.s4),
                            HeartsStatus(count: user.hearts),
                          ],
                        ],
                        SectionLabel(
                          s.myAura,
                          trailing: GestureDetector(
                            onTap: () => context.push('/aura/history'),
                            child: Text(s.seeAll, style: AppType.sm(c)),
                          ),
                        ),
                        if (loading)
                          const ListSkeleton(count: 3)
                        else if (history.isEmpty)
                          AppCard(
                            child: Text(
                              s.noAuraYet,
                              style: AppType.bodyDim(c),
                            ),
                          )
                        else
                          AppCard.flush(
                            child: Column(
                              children: [
                                for (var i = 0;
                                    i < 3 && i < history.length;
                                    i++)
                                  AuraTransactionTile(
                                    txn: history[i],
                                    divider:
                                        i != 2 && i != history.length - 1,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceHomeCard extends StatelessWidget {
  const _AttendanceHomeCard();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state.loading) {
          return AppCard(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final now = DateTime.now().toUtc();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final todayRecord = state.myRecords
            .cast<AttendanceRecord?>()
            .firstWhere((r) => r?.dateKey == todayKey, orElse: () => null);

        return AppCard(
          onTap: () => context.push('/aura/attendance'),
          child: Row(
            children: [
              Icon(
                Icons.event_available,
                color: todayRecord != null ? c.success : c.accentSolid,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  s.todaysAttendance,
                  style: AppType.bodyStrong(c),
                ),
              ),
              if (state.canCheckIn)
                ElevatedButton(
                  onPressed: state.isCheckingIn
                      ? null
                      : () => context.read<AttendanceCubit>().checkIn(),
                  child: state.isCheckingIn
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.checkIn),
                ),
              if (state.canCheckOut)
                OutlinedButton(
                  onPressed: state.isCheckingOut
                      ? null
                      : () => context
                          .read<AttendanceCubit>()
                          .checkOut('Checked out'),
                  child: state.isCheckingOut
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s.checkOut),
                ),
              if (!state.canCheckIn &&
                  !state.canCheckOut &&
                  todayRecord != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.rChip),
                  ),
                  child: Text(
                    s.doneBreak,
                    style: AppType.sm(c).copyWith(color: c.success),
                  ),
                ),
              if (!state.canCheckIn &&
                  !state.canCheckOut &&
                  todayRecord == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.textDim.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.rChip),
                  ),
                  child: Text(
                    s.absent,
                    style: AppType.sm(c).copyWith(color: c.textDim),
                  ),
                ),
              const SizedBox(width: AppSpacing.s1),
              Icon(Icons.chevron_right, color: c.textFaint, size: 20),
            ],
          ),
        );
      },
    );
  }
}
