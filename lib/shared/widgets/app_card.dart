import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Base surface (prototype `.card`): radius 22, surface bg, hairline border,
/// soft shadow. See commands/04 §4.1.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.screenPad),
    this.onTap,
    this.color,
    this.border,
    this.gradient,
  });

  /// Padding-free variant for list rows (clips children to the radius).
  const AppCard.flush({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.border,
    this.gradient,
  }) : padding = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final card = Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.rCard),
        border: border ?? Border.all(color: c.border),
        boxShadow: AppShadows.card(c),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
