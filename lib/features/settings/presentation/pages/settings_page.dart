import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/notif_pref.dart';
import '../../../../shared/domain/repositories/settings_repository.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_switch.dart';
import '../../../../shared/widgets/section_label.dart';
import '../../../../shared/widgets/segmented_control.dart';
import '../bloc/locale_cubit.dart';
import '../bloc/theme_cubit.dart';

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
          ? const Center(child: CircularProgressIndicator())
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
