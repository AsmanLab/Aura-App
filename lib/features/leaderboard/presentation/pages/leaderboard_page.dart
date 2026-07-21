import 'package:flutter/material.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/segmented_control.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../bloc/leaderboard_cubit.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  StreamSubscription<int?>? _highlightSub;
  Color? _highlightColor;

  @override
  void initState() {
    super.initState();
    _highlightSub =
        sl<SettingsRepository>().watchLeaderboardHighlightColor().listen((v) {
      if (!mounted) return;
      setState(() {
        _highlightColor = v == null ? null : Color(v);
      });
    });
  }

  @override
  void dispose() {
    _highlightSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final highlight = _highlightColor;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<LeaderboardCubit, LeaderboardState>(
          builder: (context, state) {
            if (state.loading && state.entries.isEmpty) {
              return const PageSkeleton();
            }
    final entries = state.entries;
    final meIndex =
        entries.indexWhere((e) => e.user.id == state.meId);
    final meId = state.meId ?? '';
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPad,
                    AppSpacing.s4,
                    AppSpacing.screenPad,
                    200,
                  ),
                  children: [
                    Text(s.leaderboard, style: AppType.h1(c)),
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
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: Center(
                          child: Text(s.noUsersYet,
                              style: AppType.bodyDim(c)),
                        ),
                      ),
                    if (top3.length == 3) _Podium(top3: top3, highlight: highlight, meId: meId),
                    const SizedBox(height: AppSpacing.s5),
                    AppCard.flush(
                      child: Column(
                        children: [
                      for (var i = 0; i < rest.length; i++)
                        _RestRow(
                          rank: i + 4,
                          user: rest[i].user,
                          score: rest[i].score,
                          divider: i != rest.length - 1,
                          highlight: highlight,
                          meId: meId,
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
                    user: entries[meIndex].user,
                    score: entries[meIndex].score,
                    highlight: highlight,
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
  final List<LeaderboardEntry> top3;
  final Color? highlight;
  final String meId;
  const _Podium({required this.top3, this.highlight, required this.meId});

  @override
  Widget build(BuildContext context) {
    // Visual order: 2nd, 1st, 3rd.
    Widget plinth(int i, int rank, double h) => Expanded(
          child: _Plinth(
            user: top3[i].user,
            rank: rank,
            height: h,
            score: top3[i].score,
            highlight: highlight,
            meId: meId,
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
  final Color? highlight;
  final String meId;
  const _Plinth({
    required this.user,
    required this.rank,
    required this.height,
    required this.score,
    this.highlight,
    required this.meId,
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
            ring: true,
            ringColor: user.id == meId ? highlight : null,
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
  final Color? highlight;
  final String meId;
  const _RestRow({
    required this.rank,
    required this.user,
    required this.score,
    required this.divider,
    this.highlight,
    required this.meId,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    return GestureDetector(
      onTap: () => _openProfile(context, user),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          border: Border(
            bottom: divider ? BorderSide(color: c.border) : BorderSide.none,
            left: (highlight != null && user.id == meId)
                ? BorderSide(color: highlight!, width: 3)
                : BorderSide.none,
          ),
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
                   Text(isRu ? user.role.labelRu : user.role.label, style: AppType.sm(c)),
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
  final Color? highlight;
  const _YourRank({
    required this.rank,
    required this.user,
    required this.score,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final highlightBorder = highlight != null
        ? Border(
            left: BorderSide(color: highlight!, width: 3),
          )
        : null;
    return AppCard(
      color: c.surface2,
      padding: const EdgeInsets.all(AppSpacing.s4),
      onTap: () => context.push('/aura/profile/${user.id}'),
      border: highlightBorder,
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
            ringColor: highlight,
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              '${s.you} · ${user.displayName.split(' ').first}',
              style: AppType.h3(c),
            ),
          ),
          AuraValue(score, size: 18, showUnit: false),
        ],
      ),
    );
  }
}
