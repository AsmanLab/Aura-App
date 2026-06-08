import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/category_chip.dart';

/// One received-aura transaction: tag + ±points, comment, giver + relative time.
class AuraTransactionTile extends StatelessWidget {
  final AuraTransaction txn;
  final bool divider;

  const AuraTransactionTile({
    super.key,
    required this.txn,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final cat = AuraCategory.values.asNameMap()[txn.category];
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
              if (cat != null) CategoryTag(cat: cat) else const SizedBox(),
              AuraPoints(txn.points),
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

String auraTimeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat.MMMd().format(t);
}
