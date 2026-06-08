import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';

/// 8 hearts: filled = `heart` red + glow, empty = outlined `textFaint`.
///
/// Static by default. When [interactive], tapping plays the heart-loss moment
/// (commands/06 §6.8): scale punch on the lost heart + red screen pulse +
/// haptic, then decrements. Respects reduced-motion (skips to a plain
/// decrement). Shard burst is omitted in this pass.
class HeartsRow extends StatefulWidget {
  final int count;
  final int max;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onLose; // new count after loss

  const HeartsRow({
    super.key,
    required this.count,
    this.max = 8,
    this.size = 24,
    this.interactive = false,
    this.onLose,
  });

  @override
  State<HeartsRow> createState() => _HeartsRowState();
}

class _HeartsRowState extends State<HeartsRow>
    with SingleTickerProviderStateMixin {
  late int _count = widget.count;
  // Initialized eagerly in initState — a lazy `late final` here would create
  // the Ticker on first access in dispose() (non-interactive rows never touch
  // it during their life), which throws during teardown.
  late final AnimationController _ctrl;
  late final Animation<double> _punch;

  int? _losingIndex;
  OverlayEntry? _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppDurations.heart);
    _punch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant HeartsRow old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) _count = widget.count;
  }

  @override
  void dispose() {
    if (_pulse?.mounted ?? false) _pulse!.remove();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _lose() async {
    if (_count <= 0 || _ctrl.isAnimating) return;
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      setState(() => _count--);
      widget.onLose?.call(_count);
      return;
    }

    HapticFeedback.mediumImpact();
    _showPulse();
    setState(() => _losingIndex = _count - 1);
    await _ctrl.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _count--;
      _losingIndex = null;
    });
    widget.onLose?.call(_count);
  }

  void _showPulse() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final c = Theme.of(context).extension<AppColors>()!;
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: AppDurations.heart,
            builder: (_, t, __) => DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: c.heart.withValues(alpha: 0.28 * t),
                    blurRadius: 80,
                    spreadRadius: -10,
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _pulse = entry;
    overlay.insert(entry);
    Future.delayed(AppDurations.heart, () {
      if (entry.mounted) entry.remove();
      if (_pulse == entry) _pulse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.max; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          _heart(c, i),
        ],
      ],
    );

    if (!widget.interactive) return row;
    return GestureDetector(
      onTap: _lose,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }

  Widget _heart(AppColors c, int i) {
    final filled = i < _count;
    final icon = filled
        ? Icon(
            Icons.favorite,
            size: widget.size,
            color: c.heart,
            shadows: [
              Shadow(color: c.heart.withValues(alpha: 0.55), blurRadius: 6),
            ],
          )
        : Icon(Icons.favorite_border, size: widget.size, color: c.textFaint);

    if (i != _losingIndex) return icon;
    return AnimatedBuilder(
      animation: _punch,
      builder: (_, child) =>
          Transform.scale(scale: _punch.value, child: child),
      child: icon,
    );
  }
}
