import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_gradients.dart';
import 'package:aura_app/core/theme/app_typography.dart';

/// Bottom-tab scaffold + Award FAB (commands/02, §6.0). Custom bar — no
/// Material `NavigationBar` tint/ripple.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  static const _tabs = <({IconData icon, String label})>[
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.emoji_events_rounded, label: 'Board'),
    (icon: Icons.shield_rounded, label: 'Duty'),
    (icon: Icons.menu_book_rounded, label: 'Knowledge'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      extendBody: true,
      body: shell,
      floatingActionButton: shell.currentIndex == 0
          ? _AwardFab(onTap: () => context.push('/aura/award'))
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

class _AwardFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AwardFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppGradients.aura(c),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppGradients.glow(c),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
    );
  }
}
