import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aura_app/core/theme/app_colors.dart';

/// Small mono pill `APRD-512` with a Linear-ish glyph. Static in MVP.
/// See commands/04 §4.10.
class LinearLinkChip extends StatelessWidget {
  final String id;
  final VoidCallback? onTap;

  const LinearLinkChip(this.id, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 11, color: c.textDim),
          const SizedBox(width: 4),
          Text(
            id,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: c.textDim,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
