import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/role_badge.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';

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

typedef _MyData = ({UserModel user, List<AuraTransaction> history});

/// The signed-in user's profile (Firebase) + nav rows + received-aura history.
class _MyProfileView extends StatelessWidget {
  const _MyProfileView();

  Future<_MyData?> _load() async {
    final user = await sl<AuthRepository>().getUser();
    if (user == null) return null;
    final history = await sl<ProfileRepository>().getHistory(user.id);
    return (user: user, history: history);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<_MyData?>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data;
        if (d == null) {
          return Center(
            child: Text('Could not load profile.', style: AppType.body(c)),
          );
        }
        final user = d.user;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPad,
            AppSpacing.s4,
            AppSpacing.screenPad,
            120,
          ),
          children: [
            _Identity(user: user),
            const SizedBox(height: AppSpacing.s5),
            _StatsCards(user: user),
            const SizedBox(height: AppSpacing.s5),
            AppCard.flush(
              child: Column(
                children: [
                  _NavRow(
                    icon: Icons.shield_rounded,
                    label: 'Duty',
                    onTap: () => context.push('/aura/duty'),
                  ),
                  _NavRow(
                    icon: Icons.menu_book_rounded,
                    label: 'Knowledge',
                    onTap: () => context.push('/aura/knowledge'),
                  ),
                  _NavRow(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => context.push('/aura/settings'),
                    divider: false,
                  ),
                ],
              ),
            ),
            _HistorySection(history: d.history),
          ],
        );
      },
    );
  }
}

typedef _UserData = ({
  UserModel user,
  UserModel? me,
  List<AuraTransaction> history,
});

/// Another person's profile (Firebase) — stats + aura history, award if mentor.
class _UserProfileView extends StatelessWidget {
  final String id;
  const _UserProfileView({required this.id});

  Future<_UserData?> _load() async {
    final profile = sl<ProfileRepository>();
    final user = await profile.getUser(id);
    if (user == null) return null;
    return (
      user: user,
      me: await sl<AuthRepository>().getUser(),
      history: await profile.getHistory(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<_UserData?>(
      future: _load(),
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final d = snap.data;
        final user = d?.user;
        final canAward =
            (d?.me?.canAward ?? false) && d?.me?.id != user?.id;
        return CustomScrollView(
          slivers: [
            _ProfileSliverBar(user: user),
            if (loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (d == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('User not found.', style: AppType.body(c)),
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
                    _StatsCards(user: d.user),
                    if (canAward) ...[
                      const SizedBox(height: AppSpacing.s4),
                      _AwardButton(recipientId: d.user.id),
                    ],
                    _HistorySection(history: d.history),
                  ],
                ),
              ),
          ],
        );
      },
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
                        Text(user!.positionLabel, style: AppType.sm(c)),
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
        Text(user.positionLabel, style: AppType.sm(c)),
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
    final c = Theme.of(context).extension<AppColors>()!;
    return Column(
      children: [
        // Total Aura + This week — two-up grid in one row.
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Total Aura',
                value: user.totalAura,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: _StatTile(
                label: 'This week',
                value: user.currentWeekAura,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          'Member since ${DateFormat.yMMMd().format(user.createdAt)}',
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
  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Aura history'),
        if (history.isEmpty)
          AppCard(child: Text('No Aura yet.', style: AppType.bodyDim(c)))
        else
          AppCard.flush(
            child: Column(
              children: [
                for (var i = 0; i < history.length; i++)
                  AuraTransactionTile(
                    txn: history[i],
                    divider: i != history.length - 1,
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
          border:
              divider ? Border(bottom: BorderSide(color: c.border)) : null,
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

class _AwardButton extends StatelessWidget {
  final String recipientId;
  const _AwardButton({required this.recipientId});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: () => context.push('/aura/award?internId=$recipientId'),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c.accent1, c.accent2]),
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
        ),
        child: Text(
          'Award Aura',
          style: AppType.bodyStrong(c).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
