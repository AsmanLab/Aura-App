import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/enums.dart';

/// Selectable category chip (prototype `.chip`, used in Award).
/// Rest = surface2 + category-tinted icon; selected = category-color fill.
/// See commands/04 §4.6.
class CategoryChip extends StatelessWidget {
  final AuraCategory cat;
  final bool selected;
  final VoidCallback onTap;
  final bool ru;

  const CategoryChip({
    super.key,
    required this.cat,
    required this.selected,
    required this.onTap,
    this.ru = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cat.color : c.surface2,
          borderRadius: BorderRadius.circular(AppSpacing.rChip),
          border: Border.all(
            color: selected ? cat.color : c.border,
          ),
          boxShadow: selected
              ? [BoxShadow(color: cat.color.withValues(alpha: 0.35), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cat.icon,
              size: 16,
              color: selected ? Colors.white : cat.color,
            ),
            const SizedBox(width: 6),
            Text(
              ru ? cat.labelRu : cat.label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : c.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static category tag (prototype `.cat-tag`, used in history rows): a small
/// rounded icon tile + category-color label. See commands/04 §4.6.
class CategoryTag extends StatelessWidget {
  final AuraCategory cat;
  final bool ru;

  const CategoryTag({super.key, required this.cat, this.ru = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cat.tint,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(cat.icon, size: 13, color: cat.color),
        ),
        const SizedBox(width: 6),
        Text(
          ru ? cat.labelRu : cat.label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cat.color,
          ),
        ),
      ],
    );
  }
}
