import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_value.dart';
import 'package:aura_app/core/widgets/avatar.dart';

/// The signed-in user's status card (Firebase-backed). Shown on Home; taps
/// through to the Profile tab.
class ProfileSummaryCard extends StatelessWidget {
  final UserModel user;

  const ProfileSummaryCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      onTap: () => context.go('/aura/profile'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(
                id: user.id,
                name: user.displayName,
                photoUrl: user.photoURL,
                size: 48,
                ring: true,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: AppType.h3(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.positionLabel,
                      style: AppType.sm(c),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textFaint),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Aura', style: AppType.sm(c)),
                  const SizedBox(height: AppSpacing.s1),
                  AuraValue(user.totalAura, size: 40),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('This week', style: AppType.sm(c)),
                  const SizedBox(height: AppSpacing.s1),
                  AuraValue(
                    user.currentWeekAura,
                    size: 22,
                    showUnit: false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
