import 'package:flutter/material.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/notif_pref.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/app_switch.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/core/widgets/segmented_control.dart';
import 'package:aura_app/core/settings/locale_cubit.dart';
import 'package:aura_app/core/settings/theme_cubit.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<NotifPref> _prefs = [];
  bool _quietHours = true;
  bool _loaded = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 9, minute: 0);
  Color _highlightColor = const Color(0xFF22D3EE);

  @override
  void initState() {
    super.initState();
    sl<SettingsRepository>().getNotifPrefs().then((p) {
      if (!mounted) return;
      setState(() {
        _prefs = p;
        _loaded = true;
      });
    });
    sl<SettingsRepository>().getLeaderboardHighlightColor().then((value) {
      if (!mounted || value == null) return;
      setState(() {
        _highlightColor = Color(value);
      });
    });
  }
  void _pickTime({required bool isStart}) async {
    final s = S.of(context);
    final initial = isStart ? _quietStart : _quietEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Start time' : 'End time',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _quietStart = picked;
      } else {
        _quietEnd = picked;
      }
    });
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour == 0 ? 12 : t.hour > 12 ? t.hour - 12 : t.hour;
    final period = t.hour < 12 ? 'AM' : 'PM';
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _logout() async {
    final c = Theme.of(context).extension<AppColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Log out?', style: AppType.h3(c)),
        content: Text(
          'You will be signed out of this account.',
          style: AppType.bodyDim(c),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppType.bodyStrong(c)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Log out',
              style: AppType.bodyStrong(c).copyWith(color: c.heart),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // signOut() removes the FCM token + clears the cached Google/Firebase
    // session; authStateChanges then redirects the router to /login.
    await sl<AuthRepository>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        title: Text('Settings', style: AppType.h3(c)),
      ),
      body: !_loaded
          ? const PageSkeleton()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPad),
              children: [
                const SectionLabel('Appearance'),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Dark mode', style: AppType.body(c)),
                          BlocBuilder<ThemeCubit, ThemeMode>(
                            builder: (context, mode) => AppSwitch(
                              value: mode == ThemeMode.dark,
                              onChanged: (v) =>
                                  context.read<ThemeCubit>().setDark(v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Language', style: AppType.body(c)),
                          SizedBox(
                            width: 130,
                            child: BlocBuilder<LocaleCubit, Locale>(
                              builder: (context, locale) =>
                                  SegmentedControl<String>(
                                value: locale.languageCode,
                                onChanged: (v) => context
                                    .read<LocaleCubit>()
                                    .setRu(v == 'ru'),
                                options: const [
                                  (value: 'en', label: 'EN'),
                                  (value: 'ru', label: 'RU'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SectionLabel('Notifications'),
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < _prefs.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.s4),
                        _NotifRow(
                          pref: _prefs[i],
                          ru: context.watch<LocaleCubit>().isRu,
                          onChanged: (v) async {
                            setState(
                              () => _prefs[i] = _prefs[i].copyWith(enabled: v),
                            );
                            await sl<SettingsRepository>()
                                .setNotifPref(_prefs[i].id, v);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SectionLabel('Leaderboard'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Highlight color', style: AppType.body(c)),
                      const SizedBox(height: AppSpacing.s3),
                      Wrap(
                        spacing: AppSpacing.s3,
                        runSpacing: AppSpacing.s3,
                        children: [
                          for (final color in const [
                            Color(0xFF22D3EE),
                            Color(0xFF34D399),
                            Color(0xFFA78BFA),
                            Color(0xFFF472B6),
                            Color(0xFFFBBF24),
                            Color(0xFFFB923C),
                            Color(0xFFF87171),
                            Color(0xFF60A5FA),
                          ])
                            _ColorDot(
                              color: color,
                              selected: _highlightColor == color,
                              onTap: () async {
                                setState(() => _highlightColor = color);
                                await sl<SettingsRepository>()
                                    .setLeaderboardHighlightColor(color.value);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SectionLabel('Admin'),
                AppCard(
                  child: _NavRow(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin panel',
                    onTap: () => context.push('/aura/admin/users'),
                  ),
                ),
                SectionLabel('Quiet hours'),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Enable quiet hours', style: AppType.body(c)),
                          AppSwitch(
                            value: _quietHours,
                            onChanged: (v) => setState(() => _quietHours = v),
                          ),
                        ],
                      ),
                      if (_quietHours) ...[
                        const SizedBox(height: AppSpacing.s3),
                        InkWell(
                          onTap: () => _pickTime(isStart: true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Start time', style: AppType.body(c)),
                              Text(_formatTime(_quietStart), style: AppType.bodyStrong(c)),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        InkWell(
                          onTap: () => _pickTime(isStart: false),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('End time', style: AppType.body(c)),
                              Text(_formatTime(_quietEnd), style: AppType.bodyStrong(c)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                GestureDetector(
                  onTap: _logout,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.heart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.rSm),
                      border: Border.all(
                        color: c.heart.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, size: 18, color: c.heart),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          'Log out',
                          style: AppType.bodyStrong(c).copyWith(color: c.heart),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  final NotifPref pref;
  final bool ru;
  final ValueChanged<bool> onChanged;
  const _NotifRow({
    required this.pref,
    required this.ru,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ru ? pref.labelRu : pref.label, style: AppType.body(c)),
              Text(ru ? pref.descriptionRu : pref.description, style: AppType.sm(c)),
            ],
          ),
        ),
        AppSwitch(value: pref.enabled, onChanged: onChanged),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, size: 20, color: Colors.white)
            : null,
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Row(
          children: [
            Icon(icon, color: c.accent1, size: 22),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(label, style: AppType.body(c))),
            Icon(Icons.chevron_right_rounded, color: c.textFaint),
          ],
        ),
      ),
    );
  }
}
