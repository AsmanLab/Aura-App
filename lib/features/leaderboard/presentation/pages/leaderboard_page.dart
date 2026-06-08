import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/models/enums.dart';
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
            if (state.loading && state.ranked.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            final ranked = state.ranked;
            final meIndex = ranked.indexWhere((p) => p.isYou);
            final top3 = ranked.take(3).toList();
            final rest = ranked.skip(3).toList();

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
                    if (top3.length == 3) _Podium(top3: top3),
                    const SizedBox(height: AppSpacing.s5),
                    AppCard.flush(
                      child: Column(
                        children: [
                          for (var i = 0; i < rest.length; i++)
                            _RestRow(
                              rank: i + 4,
                              person: rest[i],
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
                    child: _YourRank(rank: meIndex + 1, person: ranked[meIndex]),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<Person> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Visual order: 2nd, 1st, 3rd.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _Plinth(person: top3[1], rank: 2, height: 80)),
        Expanded(child: _Plinth(person: top3[0], rank: 1, height: 104)),
        Expanded(child: _Plinth(person: top3[2], rank: 3, height: 64)),
      ],
    );
  }
}

class _Plinth extends StatelessWidget {
  final Person person;
  final int rank;
  final double height;
  const _Plinth({required this.person, required this.rank, required this.height});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final medal = switch (rank) {
      1 => const Color(0xFFFBBF24),
      2 => const Color(0xFFCBD5E1),
      _ => const Color(0xFFD8A06B),
    };
    return GestureDetector(
      onTap: () => context.push('/aura/profile/${person.id}'),
      child: Column(
        children: [
          Avatar(
            id: person.id,
            name: person.name,
            size: rank == 1 ? 64 : 52,
            ring: rank == 1,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            person.name.split(' ').first,
            style: AppType.sm(c).copyWith(color: c.text),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          AuraValue(person.aura, size: 18, showUnit: false),
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
  final Person person;
  final bool divider;
  const _RestRow({required this.rank, required this.person, required this.divider});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: () => context.push('/aura/profile/${person.id}'),
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
            Avatar(id: person.id, name: person.name, size: 40),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: AppType.h3(c)),
                  Text(person.position, style: AppType.sm(c)),
                ],
              ),
            ),
            AuraValue(person.aura, size: 18, showUnit: false),
          ],
        ),
      ),
    );
  }
}

class _YourRank extends StatelessWidget {
  final int rank;
  final Person person;
  const _YourRank({required this.rank, required this.person});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      color: c.surface2,
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$rank', style: AppType.number(15, c)),
          ),
          const SizedBox(width: AppSpacing.s2),
          Avatar(id: person.id, name: person.name, size: 40, ring: true),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You · ${person.name.split(' ').first}',
                    style: AppType.h3(c)),
                Text('Up 2 places this week', style: AppType.sm(c)),
              ],
            ),
          ),
          AuraValue(person.aura, size: 18, showUnit: false),
        ],
      ),
    );
  }
}
