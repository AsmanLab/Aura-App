import 'package:flutter/material.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/heart_transaction_tile.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';

/// A user's heart-change history (added/removed).
class HeartsHistoryPage extends StatelessWidget {
  /// Whose history. Null = the signed-in user.
  final String? userId;
  const HeartsHistoryPage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final uid = userId ?? sl<AuthRepository>().currentUser?.id;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        title: Text(s.heartsHistory, style: AppType.h3(c)),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<HeartTransaction>>(
          future: uid == null
              ? Future.value(const [])
              : sl<ProfileRepository>().getHeartHistory(uid),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const PageSkeleton();
            }
            final txns = snap.data ?? const <HeartTransaction>[];
            if (txns.isEmpty) {
              return Center(
                child: Text(s.noHeartsYet,
                    style: AppType.bodyDim(c)),
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
                AppCard.flush(
                  child: Column(
                    children: [
                      for (var i = 0; i < txns.length; i++)
                        HeartTransactionTile(
                          txn: txns[i],
                          divider: i != txns.length - 1,
                        ),
                    ],
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
