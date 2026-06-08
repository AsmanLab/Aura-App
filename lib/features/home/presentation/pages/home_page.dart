import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final me = sl<AuthRepository>().currentUser;
    final uid = me?.id;
    final firstName = me?.displayName.split(' ').first ?? 'there';

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: c.accentSolid,
          backgroundColor: c.surface,
          // Realtime stream already keeps it fresh; this re-fetches on pull.
          onRefresh: () async {
            if (uid != null) await sl<ProfileRepository>().getHistory(uid);
          },
          child: StreamBuilder<List<AuraTransaction>>(
            stream: uid == null
                ? const Stream.empty()
                : sl<ProfileRepository>().watchHistory(uid),
            builder: (context, snap) {
              final loading = snap.connectionState == ConnectionState.waiting;
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
                      Text('Hi, $firstName', style: AppType.h1(c)),
                    ],
                  ),
                  SectionLabel(
                    'My Aura',
                    trailing: GestureDetector(
                      onTap: () => context.push('/aura/history'),
                      child: Text('See all', style: AppType.sm(c)),
                    ),
                  ),
                  if (loading)
                    const ListSkeleton(count: 3)
                  else if (history.isEmpty)
                    AppCard(
                      child: Text('No Aura yet.', style: AppType.bodyDim(c)),
                    )
                  else
                    AppCard.flush(
                      child: Column(
                        children: [
                          for (var i = 0; i < 3 && i < history.length; i++)
                            AuraTransactionTile(
                              txn: history[i],
                              divider: i != 2 && i != history.length - 1,
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
