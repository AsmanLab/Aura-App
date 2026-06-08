import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/aura_entry.dart';
import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_progress_bar.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/hearts_row.dart';
import 'package:aura_app/core/widgets/history_row.dart';
import 'package:aura_app/core/widgets/role_badge.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';

typedef _ProfileData = ({
  Person person,
  Person me,
  Map<String, Person> byId,
  List<AuraEntry> history,
});

class ProfilePage extends StatelessWidget {
  /// Null = the signed-in user (tab, from Firebase); otherwise another person
  /// (pushed, from the seed directory).
  final String? id;

  const ProfilePage({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final isOther = id != null;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: isOther
          ? AppBar(
              backgroundColor: c.bg,
              foregroundColor: c.text,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        bottom: false,
        top: !isOther,
        child: isOther ? _SeedProfileView(id: id!) : const _MyProfileView(),
      ),
    );
  }
}

/// The signed-in user's profile, parsed from Firebase (`getUser`).
class _MyProfileView extends StatelessWidget {
  const _MyProfileView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<UserModel?>(
      future: sl<AuthRepository>().getUser(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snap.data;
        if (user == null) {
          return Center(
            child: Text('Could not load profile.', style: AppType.body(c)),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPad,
            AppSpacing.s4,
            AppSpacing.screenPad,
            120,
          ),
          children: [
            Column(
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
            ),
            const SizedBox(height: AppSpacing.s5),
            AppCard(
              child: Column(
                children: [
                  Text('Total Aura', style: AppType.sm(c)),
                  const SizedBox(height: AppSpacing.s2),
                  AuraValue(user.totalAura, size: 64),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('This week', style: AppType.sm(c)),
                  AuraValue(user.currentWeekAura, size: 22, showUnit: false),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Member since', style: AppType.sm(c)),
                  Text(
                    DateFormat.yMMMd().format(user.createdAt),
                    style: AppType.number(15, c),
                  ),
                ],
              ),
            ),
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
          ],
        );
      },
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
          border: divider
              ? Border(bottom: BorderSide(color: c.border))
              : null,
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

/// Another person's profile from the seed directory (leaderboard/duty taps).
class _SeedProfileView extends StatelessWidget {
  final String id;
  const _SeedProfileView({required this.id});

  Future<_ProfileData> _load() async {
    final repo = sl<PeopleRepository>();
    final people = await repo.getPeople();
    final me = await repo.getMe();
    final person = await repo.getById(id);
    return (
      person: person,
      me: me,
      byId: {for (final p in people) p.id: p},
      history: await repo.getHistory(person.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return FutureBuilder<_ProfileData>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data!;
        final p = d.person;
        final trial = p.trial(DateTime(2026, 6, 3));
        final canAward = p.role.hasTrial && d.me.role.canAward;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPad,
            AppSpacing.s4,
            AppSpacing.screenPad,
            120,
          ),
          children: [
            Column(
              children: [
                Avatar(id: p.id, name: p.name, size: 88, ring: true),
                const SizedBox(height: AppSpacing.s3),
                Text(p.name, style: AppType.h2(c)),
                Text(p.position, style: AppType.sm(c)),
                const SizedBox(height: AppSpacing.s2),
                RoleBadge(p.role),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),
            AppCard(
              child: Column(
                children: [
                  Text('Total Aura', style: AppType.sm(c)),
                  const SizedBox(height: AppSpacing.s2),
                  AuraValue(p.aura, size: 64),
                ],
              ),
            ),
            if (p.role.hasTrial) ...[
              const SizedBox(height: AppSpacing.s4),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Hearts', style: AppType.sm(c)),
                        Text('${p.hearts}/8', style: AppType.number(15, c)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    HeartsRow(count: p.hearts, size: 24),
                  ],
                ),
              ),
            ],
            if (trial != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Trial progress', style: AppType.sm(c)),
                        Text('${trial.daysLeft} days left',
                            style: AppType.number(15, c)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    AuraProgressBar(trial.pct * 100),
                  ],
                ),
              ),
            ],
            if (canAward) ...[
              const SizedBox(height: AppSpacing.s4),
              _AwardButton(internId: p.id),
            ],
            const SectionLabel('Aura history'),
            if (d.history.isEmpty)
              AppCard(
                child: Text('No Aura yet.', style: AppType.bodyDim(c)),
              )
            else
              AppCard.flush(
                child: Column(
                  children: [
                    for (var i = 0; i < d.history.length; i++)
                      HistoryRow(
                        entry: d.history[i],
                        giverId: d.history[i].byPersonId,
                        giverName: d.byId[d.history[i].byPersonId]?.name ?? '?',
                        showDivider: i != d.history.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AwardButton extends StatelessWidget {
  final String internId;
  const _AwardButton({required this.internId});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: () => context.push('/aura/award?internId=$internId'),
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
