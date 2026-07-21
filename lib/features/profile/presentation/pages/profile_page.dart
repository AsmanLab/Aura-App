import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/attendance_transaction.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/attendance_month_calendar.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/widgets/heart_transaction_tile.dart';
import 'package:aura_app/core/widgets/hearts_status.dart';
import 'package:aura_app/core/widgets/role_badge.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:aura_app/features/profile/presentation/bloc/user_profile_cubit.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  /// Null = the signed-in user (tab); otherwise another person (pushed).
  final String? id;

  const ProfilePage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final isOther = id != null;
    return Scaffold(
      backgroundColor: c.bg,
      // Other profiles use a collapsing SliverAppBar (handles its own inset +
      // back button); own profile is a plain scrolling list.
      body: isOther
          ? _UserProfileView(id: id!)
          : const SafeArea(bottom: false, child: _MyProfileView()),
    );
  }
}

/// The signed-in user's profile (Firebase) + nav rows + received-aura history.
/// Realtime: streams the user doc + aura history (cached so rebuilds don't
/// re-subscribe).
class _MyProfileView extends StatefulWidget {
  const _MyProfileView();

  @override
  State<_MyProfileView> createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<_MyProfileView> {
  late final String? _uid = sl<AuthRepository>().currentUser?.id;
  late final Stream<UserModel?>? _userStream =
      _uid == null ? null : sl<ProfileRepository>().watchUser(_uid);
  late final Stream<List<AuraTransaction>>? _histStream =
      _uid == null ? null : sl<ProfileRepository>().watchHistory(_uid);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    if (_uid == null) {
      return Center(
        child: Text(s.userNotFound, style: AppType.body(c)),
      );
    }
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, userSnap) {
        if (!userSnap.hasData &&
            userSnap.connectionState == ConnectionState.waiting) {
          return const PageSkeleton(header: true);
        }
        final user = userSnap.data;
        if (user == null) {
          return Center(
            child: Text(s.userNotFound, style: AppType.body(c)),
          );
        }
        return StreamBuilder<List<AuraTransaction>>(
          stream: _histStream,
          builder: (context, histSnap) {
            final history = histSnap.data ?? const <AuraTransaction>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPad,
                AppSpacing.s4,
                AppSpacing.screenPad,
                120,
              ),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined, color: c.text),
                    tooltip: s.editProfile,
                    onPressed: () => context.push('/aura/profile/edit'),
                  ),
                ),
                _Identity(user: user),
                const SizedBox(height: AppSpacing.s5),
                _StatsCards(user: user),
                if (user.role == Role.intern) ...[
                  const SizedBox(height: AppSpacing.s4),
                  HeartsStatus(
                    count: user.hearts,
                    onTap: () => context.push('/aura/hearts-history'),
                  ),
                ],
                const SizedBox(height: AppSpacing.s5),
                AppCard.flush(
                  child: Column(
                    children: [
                      _NavRow(
                        icon: Icons.shield_rounded,
                        label: s.duty,
                        onTap: () => context.push('/aura/duty'),
                      ),
                      _NavRow(
                        icon: Icons.menu_book_rounded,
                        label: s.knowledge,
                        onTap: () => context.push('/aura/knowledge'),
                      ),
                      if (user.role == Role.admin)
                        _NavRow(
                          icon: Icons.admin_panel_settings_rounded,
                          label: s.adminPanel,
                          onTap: () => context.push('/aura/admin/users'),
                        ),
                      _NavRow(
                        icon: Icons.settings_rounded,
                        label: s.settings,
                        onTap: () => context.push('/aura/settings'),
                        divider: false,
                      ),
                    ],
                  ),
                ),
                _HistorySection(history: history),
              ],
            );
          },
        );
      },
    );
  }
}

/// Another person's profile — aura, hearts, attendance calendar.
/// Data loaded via [UserProfileCubit] (provided by the route).
class _UserProfileView extends StatefulWidget {
  final String id;
  const _UserProfileView({required this.id});

  @override
  State<_UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<_UserProfileView> {
  // One-shot: viewer role rarely changes, cubit handles the subject.
  late final Future<UserModel?> _meFuture = sl<AuthRepository>().getUser();

  void _showAttendanceDetails(
      BuildContext context, AppColors c, AttendanceRecord r) {
    final s = S.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.rLg)),
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
              DateFormat('EEEE, MMMM d').format(DateTime.parse(r.dateKey)),
              style: AppType.h3(c),
            ),
            const SizedBox(height: AppSpacing.s4),
            _AttendanceRow(
              icon: Icons.login,
              label: s.checkIn,
              value: DateFormat('HH:mm').format(r.timestamp.toLocal()),
              c: c,
            ),
            if (r.lunchStart != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _AttendanceRow(
                icon: Icons.restaurant,
                label: s.lunchStart,
                value: DateFormat('HH:mm').format(r.lunchStart!.toLocal()),
                c: c,
              ),
            ],
            if (r.lunchEnd != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _AttendanceRow(
                icon: Icons.restaurant_outlined,
                label: s.lunchEnd,
                value: DateFormat('HH:mm').format(r.lunchEnd!.toLocal()),
                c: c,
              ),
            ],
            if (r.checkOutNote != null) ...[
              const SizedBox(height: AppSpacing.s3),
              _AttendanceRow(
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
    return FutureBuilder<UserModel?>(
      future: _meFuture,
      builder: (context, meSnap) {
        final me = meSnap.data;
        return BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            final user = state.user;
            final canAward = (me?.canAward ?? false) && me?.id != user?.id;
            final isIntern = user?.role == Role.intern;

            return CustomScrollView(
              slivers: [
                _ProfileSliverBar(user: user),
                if (state.loading)
                  const SliverToBoxAdapter(child: PageSkeleton())
                else if (user == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(s.userNotFound, style: AppType.body(c)),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPad,
                      AppSpacing.s4,
                      AppSpacing.screenPad,
                      120,
                    ),
                    sliver: SliverList.list(
                      children: [
                        // ── Aura stats ──
                        _StatsCards(user: user),

                        // ── Hearts (interns only) ──
                        if (isIntern) ...[
                          const SizedBox(height: AppSpacing.s4),
                          HeartsStatus(
                            count: user.hearts,
                            onTap: () => context.push(
                              '/aura/hearts-history?userId=${user.id}',
                            ),
                          ),
                          if (state.heartHistory.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s2),
                            AppCard.flush(
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < state.heartHistory.length && i < 3;
                                      i++)
                                    HeartTransactionTile(
                                      txn: state.heartHistory[i],
                                      divider: i != 2 &&
                                          i != state.heartHistory.length - 1,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        // ── Award / Hearts buttons ──
                        if (canAward) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: s.awardAura,
                                  gradient: true,
                                  onTap: () => context.push(
                                    '/aura/award?internId=${user.id}',
                                  ),
                                ),
                              ),
                              if (isIntern) ...[
                                const SizedBox(width: AppSpacing.s3),
                                Expanded(
                                  child: _ActionButton(
                                    label: s.giveHearts,
                                    color: c.heart,
                                    onTap: () => context.push(
                                      '/aura/hearts?recipientId=${user.id}',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],

                        // ── Attendance calendar ──
                        SectionLabel(s.attendance),
                        AttendanceMonthCalendar(
                          records: state.attendanceRecords,
                          onDayTap: (r) =>
                              _showAttendanceDetails(context, c, r),
                        ),

                        // ── Aura history ──
                        _HistorySection(
                          history: state.auraHistory,
                          seeAllUserId: user.id,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors c;
  const _AttendanceRow({
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

/// Collapsing header: expanded = avatar + name + position; collapsed = name bar.
class _ProfileSliverBar extends StatelessWidget {
  final UserModel? user;
  const _ProfileSliverBar({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return SliverAppBar(
      pinned: true,
      expandedHeight: user == null ? kToolbarHeight : 230,
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.text,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: user == null
          ? null
          : FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 14),
              title: Text(user!.displayName, style: AppType.h3(c)),
              background: SafeArea(
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 44),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Avatar(
                          id: user!.id,
                          name: user!.displayName,
                          photoUrl: user!.photoURL,
                          size: 76,
                          ring: true,
                        ),
                        const SizedBox(height: AppSpacing.s2),
                         Text(isRu ? user!.role.labelRu : user!.role.label, style: AppType.sm(c)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Identity extends StatelessWidget {
  final UserModel user;
  const _Identity({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return Column(
      children: [
        Avatar(
          id: user.id,
          name: user.displayName,
          photoUrl: user.photoURL,
          size: 88,
          ring: true,
        ),
        const SizedBox(height: AppSpacing.s3),
        Text(user.displayName, style: AppType.h2(c)),
        Text(isRu ? user.role.labelRu : user.role.label, style: AppType.sm(c)),
        const SizedBox(height: AppSpacing.s2),
        RoleBadge(user.role),
      ],
    );
  }
}

class _StatsCards extends StatelessWidget {
  final UserModel user;
  const _StatsCards({required this.user});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        // Total Aura + This week — two-up grid in one row.
        Row(
          children: [
            Expanded(
              child: _StatTile(label: s.totalAura, value: user.totalAura),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: _StatTile(label: s.thisWeek, value: user.currentWeekAura),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          s.memberSince(DateFormat.yMMMd().format(user.createdAt)),
          style: AppType.sm(c).copyWith(color: c.textFaint),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.sm(c)),
          const SizedBox(height: AppSpacing.s2),
          AuraValue(value, size: 36, showUnit: false),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<AuraTransaction> history;

  /// Whose history "See all" opens. Null = the signed-in user.
  final String? seeAllUserId;

  const _HistorySection({required this.history, this.seeAllUserId});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final shown = history.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          s.auraHistory,
          trailing: history.isEmpty
              ? null
              : GestureDetector(
                  onTap: () => context.push(
                    seeAllUserId == null
                        ? '/aura/history'
                        : '/aura/history?userId=$seeAllUserId',
                  ),
                  child: Text(s.seeAll, style: AppType.sm(c)),
                ),
        ),
        if (shown.isEmpty)
          AppCard(child: Text(s.noAuraYet, style: AppType.bodyDim(c)))
        else
          AppCard.flush(
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++)
                  AuraTransactionTile(
                    txn: shown[i],
                    divider: i != shown.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool divider;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(AppSpacing.rSm),
              ),
              child: Icon(icon, size: 18, color: c.accentSolid),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(label, style: AppType.h3(c))),
            Icon(Icons.chevron_right, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool gradient;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.gradient = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: gradient
              ? LinearGradient(colors: [c.accent1, c.accent2])
              : null,
          color: gradient ? null : color,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
        ),
        child: Text(
          label,
          style: AppType.bodyStrong(c).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
