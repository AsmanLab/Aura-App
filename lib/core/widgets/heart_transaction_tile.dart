import 'package:flutter/material.dart';

import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/avatar.dart';

/// One heart change: added (green) / removed (red), comment, giver + time.
class HeartTransactionTile extends StatelessWidget {
  final HeartTransaction txn;
  final bool divider;

  const HeartTransactionTile({
    super.key,
    required this.txn,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final added = txn.delta > 0;
    final color = added ? c.success : c.heart;
    final giver = txn.fromName.isNotEmpty ? txn.fromName : 'Someone';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, size: 16, color: color),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    added ? 'Heart added' : 'Heart removed',
                    style: AppType.bodyStrong(c).copyWith(color: color),
                  ),
                ],
              ),
              Text(
                added ? '+1' : '−1',
                style: AppType.number(15, c).copyWith(color: color),
              ),
            ],
          ),
          if (txn.comment.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(txn.comment, style: AppType.body(c)),
          ],
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Avatar(
                id: txn.fromUserId,
                name: giver,
                photoUrl: txn.fromPhotoURL,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '${giver.split(' ').first} · ${auraTimeAgo(txn.timestamp)}',
                style: AppType.sm(c),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
