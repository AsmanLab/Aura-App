import 'package:flutter/material.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';

/// Animated shimmer sweep applied to its (skeleton) child.
class Skeleton extends StatefulWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1 - 2 * t, 0),
            end: Alignment(1 - 2 * t, 0),
            colors: [c.surface2, c.surface3, c.surface2],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A grey placeholder block.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppSpacing.rSm,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface2,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// A skeleton row matching `AuraTransactionTile`'s shape (history feeds).
class TransactionTileSkeleton extends StatelessWidget {
  const TransactionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 90, height: 18, radius: 999),
              SkeletonBox(width: 36, height: 18),
            ],
          ),
          SizedBox(height: AppSpacing.s3),
          SkeletonBox(width: 220, height: 12),
          SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              SkeletonBox(height: 20, circle: true),
              SizedBox(width: AppSpacing.s2),
              SkeletonBox(width: 120, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// N stacked transaction skeletons inside a flush card, shimmering.
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Skeleton(child: _card(context, count));
  }
}

Widget _card(BuildContext context, int count) {
  final c = Theme.of(context).extension<AppColors>()!;
  return Container(
    decoration: BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(AppSpacing.rCard),
      border: Border.all(color: c.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [for (var i = 0; i < count; i++) const TransactionTileSkeleton()],
    ),
  );
}

/// Generic full-page loader: title, two stat tiles, then a list. Drop into any
/// page's loading branch (it's a non-scrolling Column).
class PageSkeleton extends StatelessWidget {
  final bool header;
  const PageSkeleton({super.key, this.header = false});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    Widget tile(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppSpacing.rCard),
            border: Border.all(color: c.border),
          ),
        );
    return Skeleton(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPad,
          AppSpacing.s4,
          AppSpacing.screenPad,
          AppSpacing.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (header) ...[
              const SkeletonBox(height: 88, circle: true),
              const SizedBox(height: AppSpacing.s3),
              const SkeletonBox(width: 160, height: 22),
              const SizedBox(height: AppSpacing.s5),
            ] else ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: SkeletonBox(width: 180, height: 28),
              ),
              const SizedBox(height: AppSpacing.s5),
            ],
            Row(
              children: [
                Expanded(child: tile(80)),
                const SizedBox(width: AppSpacing.s3),
                Expanded(child: tile(80)),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),
            _card(context, 4),
          ],
        ),
      ),
    );
  }
}
