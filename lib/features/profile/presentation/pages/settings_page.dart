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
                          onChanged: (v) => setState(
                            () => _prefs[i] = _prefs[i].copyWith(enabled: v),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SectionLabel('Quiet hours'),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('From 10 PM to 9 AM', style: AppType.sm(c)),
                            Icon(Icons.chevron_right, color: c.textFaint),
                          ],
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
              Text(pref.description, style: AppType.sm(c)),
            ],
          ),
        ),
        AppSwitch(value: pref.enabled, onChanged: onChanged),
      ],
    );
  }
}
