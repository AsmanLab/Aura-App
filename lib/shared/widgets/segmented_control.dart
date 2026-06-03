import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';

typedef SegmentOption<T> = ({T value, String label});

/// Animated pill segmented control (Leaderboard filter, Settings language).
/// See commands/04 §4.9.
class SegmentedControl<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final index = options.indexWhere((o) => o.value == value);

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(AppSpacing.rChip),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final segW = box.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppDurations.med,
                curve: Curves.easeOutCubic,
                left: segW * (index < 0 ? 0 : index),
                width: segW,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.aura(c),
                    borderRadius: BorderRadius.circular(AppSpacing.rChip),
                    boxShadow: AppGradients.glow(c, blur: 10),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final o in options)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(o.value),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: Text(
                            o.label,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: o.value == value
                                  ? Colors.white
                                  : c.textDim,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
