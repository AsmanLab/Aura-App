import 'package:flutter/material.dart';

import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/hearts_row.dart';

/// Hearts card: "Hearts m/8" + the heart row. Shown for interns. Tap (when
/// [onTap] is set) opens the heart-change history.
class HeartsStatus extends StatelessWidget {
  final int count;
  final int max;
  final VoidCallback? onTap;

  const HeartsStatus({
    super.key,
    required this.count,
    this.max = UserModel.maxHearts,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hearts', style: AppType.sm(c)),
              Row(
                children: [
                  Text('$count/$max', style: AppType.number(15, c)),
                  if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.s1),
                    Icon(Icons.chevron_right, size: 18, color: c.textFaint),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          HeartsRow(count: count, max: max, size: 22),
        ],
      ),
    );
  }
}
