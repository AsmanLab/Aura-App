import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/segmented_control.dart';
import '../bloc/leaderboard_cubit.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
          builder: (context, state) {
            if (state.loading && state.users.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = state.users;
            final meIndex = users.indexWhere((u) => u.id == state.meId);
            final top3 = users.take(3).toList();
            final rest = users.skip(3).toList();

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPad,
                    AppSpacing.s4,
                    AppSpacing.screenPad,
                    140,
                  ),
                  children: [
                    Text('Leaderboard', style: AppType.h1(c)),
                    const SizedBox(height: AppSpacing.s4),
                    SegmentedControl<LbFilter>(
                      value: state.filter,
                      onChanged: (f) =>
                          context.read<LeaderboardCubit>().setFilter(f),
                      options: [
                        for (final f in LbFilter.values)
                          (value: f, label: f.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    if (users.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: Center(
                          child: Text('No users yet.',
                              style: AppType.bodyDim(c)),
                        ),
                      ),
                    if (top3.length == 3)
                      _Podium(top3: top3, state: state),
                    const SizedBox(height: AppSpacing.s5),
                    AppCard.flush(
                      child: Column(
                        children: [
                          for (var i = 0; i < rest.length; i++)
                            _RestRow(
                              rank: i + 4,
                              user: rest[i],
                              score: state.scoreOf(rest[i]),
                              divider: i != rest.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (meIndex >= 0)
                  Positioned(
                    left: AppSpacing.screenPad,
                    right: AppSpacing.screenPad,
                    bottom: 100,
                    child: _YourRank(
                      rank: meIndex + 1,
                      user: users[meIndex],
                      score: state.scoreOf(users[meIndex]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void _openProfile(BuildContext context, UserModel user) {
  context.push('/aura/profile/${user.id}');
}

class _Podium extends StatelessWidget {
  final List<UserModel> top3;
  final LeaderboardState state;
  const _Podium({required this.top3, required this.state});

  @override
  Widget build(BuildContext context) {
    // Visual order: 2nd, 1st, 3rd.
    Widget plinth(int i, int rank, double h) => Expanded(
          child: _Plinth(
            user: top3[i],
            rank: rank,
            height: h,
            score: state.scoreOf(top3[i]),
          ),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        plinth(1, 2, 80),
        plinth(0, 1, 104),
        plinth(2, 3, 64),
      ],
    );
  }
}

class _Plinth extends StatelessWidget {
  final UserModel user;
  final int rank;
  final double height;
  final int score;
  const _Plinth({
    required this.user,
    required this.rank,
    required this.height,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final medal = switch (rank) {
      1 => const Color(0xFFFBBF24),
      2 => const Color(0xFFCBD5E1),
      _ => const Color(0xFFD8A06B),
    };
    return GestureDetector(
      onTap: () => _openProfile(context, user),
      child: Column(
        children: [
          Avatar(
            id: user.id,
            name: user.displayName,
            photoUrl: user.photoURL,
            size: rank == 1 ? 64 : 52,
            ring: rank == 1,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            user.displayName.split(' ').first,
            style: AppType.sm(c).copyWith(color: c.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          AuraValue(score, size: 18, showUnit: false),
          const SizedBox(height: AppSpacing.s2),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.rSm),
              ),
              border: Border.all(color: c.border),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: AppSpacing.s2),
            child: Text(
              '$rank',
              style: AppType.number(20, c).copyWith(color: medal),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestRow extends StatelessWidget {
  final int rank;
  final UserModel user;
  final int score;
  final bool divider;
  const _RestRow({
    required this.rank,
    required this.user,
    required this.score,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: () => _openProfile(context, user),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: AppType.number(15, c).copyWith(color: c.textFaint),
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Avatar(
              id: user.id,
              name: user.displayName,
              photoUrl: user.photoURL,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: AppType.h3(c)),
                  Text(user.email, style: AppType.sm(c)),
                ],
              ),
            ),
            AuraValue(score, size: 18, showUnit: false),
          ],
        ),
      ),
    );
  }
}

class _YourRank extends StatelessWidget {
  final int rank;
  final UserModel user;
  final int score;
  const _YourRank({
    required this.rank,
    required this.user,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      color: c.surface2,
      padding: const EdgeInsets.all(AppSpacing.s4),
      onTap: () => context.push('/aura/profile/${user.id}'),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$rank', style: AppType.number(15, c)),
          ),
          const SizedBox(width: AppSpacing.s2),
          Avatar(
            id: user.id,
            name: user.displayName,
            photoUrl: user.photoURL,
            size: 40,
            ring: true,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              'You · ${user.displayName.split(' ').first}',
              style: AppType.h3(c),
            ),
          ),
          AuraValue(score, size: 18, showUnit: false),
        ],
      ),
    );
  }
}
