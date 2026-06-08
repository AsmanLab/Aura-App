import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/features/auth/presentation/auth_providers.dart';

/// Bottom-tab scaffold + Award FAB (commands/02, §6.0). Custom bar — no
/// Material `NavigationBar` tint/ripple.
///
/// Mentor mode: the Award FAB only shows for users whose role can award.
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  static const _tabs = <({IconData icon, String label})>[
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.emoji_events_rounded, label: 'Board'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).extension<AppColors>()!;
    final canAward =
        ref.watch(currentUserProvider).valueOrNull?.canAward ?? false;
    return Scaffold(
      backgroundColor: c.bg,
      extendBody: true,
      body: shell,
      floatingActionButton: (shell.currentIndex == 0 && canAward)
          ? const _ExpandableFab()
          : null,
      bottomNavigationBar: _BottomBar(
        tabs: _tabs,
        current: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<({IconData icon, String label})> tabs;
  final int current;
  final ValueChanged<int> onTap;
  const _BottomBar({
    required this.tabs,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: c.bg.withValues(alpha: 0.8),
            border: Border(top: BorderSide(color: c.border)),
          ),
          padding: const EdgeInsets.only(bottom: 18, top: 8),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: _TabButton(tab: tabs[i], active: i == current),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final ({IconData icon, String label}) tab;
  final bool active;
  const _TabButton({required this.tab, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final color = active ? c.accentSolid : c.textFaint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          tab.icon,
          size: 24,
          color: color,
          shadows: active
              ? [Shadow(color: c.accentSolid.withValues(alpha: 0.6), blurRadius: 12)]
              : null,
        ),
        const SizedBox(height: 3),
        Text(
          tab.label,
          style: AppType.label(c).copyWith(
            color: active ? c.text : c.textFaint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Expandable FAB: tap to reveal Aura + Hearts actions (mentor mode).
class _ExpandableFab extends StatefulWidget {
  const _ExpandableFab();

  @override
  State<_ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<_ExpandableFab> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _go(String route) {
    setState(() => _open = false);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    // Right angle: Hearts above the FAB, Aura to its left.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Hearts — above.
        AnimatedSize(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MiniAction(
                    icon: Icons.favorite,
                    label: 'Hearts',
                    color: c.heart,
                    onTap: () => _go('/aura/hearts'),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Aura — to the left.
            AnimatedSize(
              duration: AppDurations.fast,
              curve: Curves.easeOutCubic,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _MiniAction(
                        icon: Icons.auto_awesome,
                        label: 'Aura',
                        color: c.accentSolid,
                        onTap: () => _go('/aura/award'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppGradients.aura(c),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppGradients.glow(c),
                ),
                child: AnimatedRotation(
                  turns: _open ? 0.125 : 0,
                  duration: AppDurations.fast,
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppSpacing.rChip),
              border: Border.all(color: c.border),
              boxShadow: AppShadows.card(c),
            ),
            child: Text(label, style: AppType.bodyStrong(c)),
          ),
          const SizedBox(width: AppSpacing.s2),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
              boxShadow: AppShadows.card(c),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ],
      ),
    );
  }
}
