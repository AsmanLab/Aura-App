import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';

/// Track + gradient fill with glow, used for trial progress. Fills in on first
/// build. See commands/04 §4.7.
class AuraProgressBar extends StatefulWidget {
  final double pct; // 0..100
  final double height;

  const AuraProgressBar(this.pct, {super.key, this.height = 10});

  @override
  State<AuraProgressBar> createState() => _AuraProgressBarState();
}

class _AuraProgressBarState extends State<AuraProgressBar> {
  double _shown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = widget.pct.clamp(0, 100));
    });
  }

  @override
  void didUpdateWidget(covariant AuraProgressBar old) {
    super.didUpdateWidget(old);
    if (old.pct != widget.pct) {
      setState(() => _shown = widget.pct.clamp(0, 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.rChip),
      child: Container(
        height: widget.height,
        color: c.surface3,
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, box) => AnimatedContainer(
              duration: AppDurations.med,
              curve: Curves.easeOutCubic,
              width: box.maxWidth * (_shown / 100),
              decoration: BoxDecoration(
                gradient: AppGradients.aura(c),
                borderRadius: BorderRadius.circular(AppSpacing.rChip),
                boxShadow: AppGradients.glow(c, blur: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
