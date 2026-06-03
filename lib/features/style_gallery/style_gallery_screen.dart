import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

/// Throwaway Stage-1 screen: renders every design token so they can be eyeballed
/// against the prototype in both dark and light. Not part of the shipped app.
class StyleGalleryScreen extends StatefulWidget {
  const StyleGalleryScreen({super.key});

  @override
  State<StyleGalleryScreen> createState() => _StyleGalleryScreenState();
}

class _StyleGalleryScreenState extends State<StyleGalleryScreen> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    // Local theme override so the gallery previews either palette in isolation.
    return Theme(
      data: _dark ? AppTheme.dark : AppTheme.light,
      child: Builder(
        builder: (context) {
          final c = Theme.of(context).extension<AppColors>()!;
          return Scaffold(
            backgroundColor: c.bg,
            appBar: AppBar(
              backgroundColor: c.bg,
              foregroundColor: c.text,
              elevation: 0,
              title: Text('Style Gallery', style: AppType.h3(c)),
              actions: [
                Row(
                  children: [
                    Icon(
                      _dark ? Icons.dark_mode : Icons.light_mode,
                      color: c.textDim,
                      size: 18,
                    ),
                    Switch(
                      value: _dark,
                      activeThumbColor: c.accentSolid,
                      onChanged: (v) => setState(() => _dark = v),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                  ],
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPad),
              children: [
                _section(c, 'GRADIENT & GLOW'),
                _gradientDemo(c),
                const SizedBox(height: AppSpacing.s6),

                _section(c, 'AURA NUMBER'),
                _auraNumber(c),
                const SizedBox(height: AppSpacing.s6),

                _section(c, 'COLORS'),
                _swatches(c),
                const SizedBox(height: AppSpacing.s6),

                _section(c, 'TYPOGRAPHY'),
                ..._typeScale(c),
                const SizedBox(height: AppSpacing.s6),

                _section(c, 'RADII'),
                _radii(c),
                const SizedBox(height: AppSpacing.s8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(AppColors c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
    child: Text(label.toUpperCase(), style: AppType.label(c)),
  );

  Widget _gradientDemo(AppColors c) => Container(
    height: 96,
    decoration: BoxDecoration(
      gradient: AppGradients.aura(c),
      borderRadius: BorderRadius.circular(AppSpacing.rCard),
      boxShadow: AppGradients.glow(c),
    ),
    alignment: Alignment.center,
    child: Text(
      'accent1 → accent2',
      style: AppType.bodyStrong(c).copyWith(color: Colors.white),
    ),
  );

  Widget _auraNumber(AppColors c) {
    final numStyle = AppType.number(64, c).copyWith(height: 0.95);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Stack(
          children: [
            // glow underlay
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Text(
                  '1,840',
                  style: numStyle.copyWith(
                    color: c.accentSolid.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            ShaderMask(
              shaderCallback: (r) => AppGradients.aura(c).createShader(r),
              blendMode: BlendMode.srcIn,
              child: Text(
                '1,840',
                style: numStyle.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.s2),
        Text(
          'AURA',
          style: AppType.label(c).copyWith(color: c.textDim, fontSize: 19),
        ),
      ],
    );
  }

  Widget _swatches(AppColors c) {
    final entries = <(String, Color)>[
      ('bg', c.bg),
      ('bg2', c.bg2),
      ('surface', c.surface),
      ('surface2', c.surface2),
      ('surface3', c.surface3),
      ('border', c.border),
      ('borderStrong', c.borderStrong),
      ('text', c.text),
      ('textDim', c.textDim),
      ('textFaint', c.textFaint),
      ('accent1', c.accent1),
      ('accent2', c.accent2),
      ('accentSolid', c.accentSolid),
      ('accentSoft', c.accentSoft),
      ('heart', c.heart),
      ('success', c.success),
      ('warning', c.warning),
    ];
    return Wrap(
      spacing: AppSpacing.s3,
      runSpacing: AppSpacing.s3,
      children: [
        for (final (name, color) in entries)
          SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSpacing.rSm),
                    border: Border.all(color: c.border),
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  name,
                  style: AppType.label(c),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _typeScale(AppColors c) => [
    Text('display 64', style: AppType.display(c).copyWith(fontSize: 40)),
    const SizedBox(height: AppSpacing.s2),
    Text('h1 · Hi, Aibek', style: AppType.h1(c)),
    Text('h2 · Leaderboard', style: AppType.h2(c)),
    Text('h3 · Row title', style: AppType.h3(c)),
    Text('body · Body copy and list text.', style: AppType.body(c)),
    Text('bodyStrong · Emphasised body.', style: AppType.bodyStrong(c)),
    Text('sm · Meta / position', style: AppType.sm(c)),
    Text('LABEL · SECTION', style: AppType.label(c)),
    Text('number · 1,840 / +40 / Jun 3', style: AppType.number(15, c)),
  ];

  Widget _radii(AppColors c) {
    final radii = <(String, double)>[
      ('rSm 14', AppSpacing.rSm),
      ('rCard 22', AppSpacing.rCard),
      ('rLg 30', AppSpacing.rLg),
    ];
    return Row(
      children: [
        for (final (name, r) in radii) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(color: c.border),
                    boxShadow: AppShadows.card(c),
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                Text(name, style: AppType.label(c)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
        ],
      ],
    );
  }
}
