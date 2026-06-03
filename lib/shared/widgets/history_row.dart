import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../domain/entities/aura_entry.dart';
import 'aura_value.dart';
import 'avatar.dart';
import 'category_chip.dart';
import 'linear_link_chip.dart';

/// One Aura history entry (commands/06 §6.3): category tag + ±points, reason,
/// giver footer, optional Linear chip.
class HistoryRow extends StatelessWidget {
  final AuraEntry entry;
  final String giverId;
  final String giverName;
  final bool showDivider;
  final bool ru;

  const HistoryRow({
    super.key,
    required this.entry,
    required this.giverId,
    required this.giverName,
    this.showDivider = true,
    this.ru = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: c.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CategoryTag(cat: entry.category, ru: ru),
              AuraPoints(entry.points),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(entry.reason, style: AppType.body(c)),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Avatar(id: giverId, name: giverName, size: 20),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '${giverName.split(' ').first} · ${entry.when}',
                style: AppType.sm(c),
              ),
              const Spacer(),
              if (entry.linearId != null) LinearLinkChip(entry.linearId!),
            ],
          ),
        ],
      ),
    );
  }
}
