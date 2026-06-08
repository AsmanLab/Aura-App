import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';

/// The glow number (prototype `.aura-val`): gradient-filled Space Grotesk
/// numerals + outer glow, optional "AURA" unit. See commands/04 §4.2.
class AuraValue extends StatelessWidget {
  final int value;
  final double size;
  final bool showUnit;
  final double glow; // 0..1

  const AuraValue(
    this.value, {
    super.key,
    this.size = 64,
    this.showUnit = true,
    this.glow = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final text = NumberFormat.decimalPattern().format(value);
    final numStyle = TextStyle(fontFamily: 'SpaceGrotesk', 
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 0.95,
      letterSpacing: -0.03 * size,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Stack(
          children: [
            // glow underlay
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 12 * glow,
                  sigmaY: 12 * glow,
                ),
                child: Text(
                  text,
                  style: numStyle.copyWith(
                    color: c.accentSolid.withValues(alpha: 0.8 * glow),
                  ),
                ),
              ),
            ),
            ShaderMask(
              shaderCallback: (r) => AppGradients.aura(c).createShader(r),
              blendMode: BlendMode.srcIn,
              child: Text(text, style: numStyle.copyWith(color: Colors.white)),
            ),
          ],
        ),
        if (showUnit) ...[
          const SizedBox(width: 8),
          Text(
            'AURA',
            style: TextStyle(fontFamily: 'Manrope', 
              fontSize: size * 0.3,
              fontWeight: FontWeight.w700,
              color: c.textDim,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}

/// Inline ±N (prototype history/award): gradient for positive, solid warm red
/// for negative (no gradient, no glow). See commands/04 §4.2.
class AuraPoints extends StatelessWidget {
  final int pts;
  final double size;

  const AuraPoints(this.pts, {super.key, this.size = 17});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final style = TextStyle(fontFamily: 'SpaceGrotesk', 
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.02 * size,
    );

    if (pts < 0) {
      return Text(
        '−${pts.abs()}',
        style: style.copyWith(color: const Color(0xFFFF7A88)),
      );
    }
    return ShaderMask(
      shaderCallback: (r) => AppGradients.aura(c).createShader(r),
      blendMode: BlendMode.srcIn,
      child: Text('+$pts', style: style.copyWith(color: Colors.white)),
    );
  }
}
