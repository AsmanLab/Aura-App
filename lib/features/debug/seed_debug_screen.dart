import 'package:flutter/material.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/repositories/duty_repository.dart';
import 'package:aura_app/core/domain/repositories/knowledge_repository.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';
import 'package:aura_app/core/models/enums.dart';

/// Stage-3 exit check: pull every repository through the service locator and
/// print what it returns. Not part of the shipped app.
class SeedDebugScreen extends StatelessWidget {
  const SeedDebugScreen({super.key});

  Future<List<String>> _dump() async {
    final people = sl<PeopleRepository>();
    final duty = sl<DutyRepository>();
    final knowledge = sl<KnowledgeRepository>();
    final settings = sl<SettingsRepository>();

    final lines = <String>[];

    final me = await people.getMe();
    final onDuty = await people.getOnDuty();
    lines.add('me: ${me.name} (${me.role.label}) · ${me.aura} aura · '
        '${me.hearts}/8 hearts');
    final t = me.trial(DateTime(2026, 6, 3));
    if (t != null) {
      lines.add('  trial: ${(t.pct * 100).round()}% · ${t.daysLeft} days left');
    }
    lines.add('on duty: ${onDuty.name}');

    lines.add('');
    lines.add('LEADERBOARD (all-time, interns):');
    final lb = await people.getLeaderboard(LbFilter.allTime);
    for (var i = 0; i < lb.length; i++) {
      lines.add('  ${i + 1}. ${lb[i].name} — ${lb[i].aura}');
    }
    final week = await people.getLeaderboard(LbFilter.week);
    lines.add('  (week top: ${week.first.name} = ${week.first.aura})');

    lines.add('');
    lines.add('HISTORY (aibek): ${(await people.getHistory('aibek')).length} '
        'entries');
    for (final e in await people.getHistory('aibek')) {
      lines.add('  ${e.points >= 0 ? '+' : ''}${e.points} '
          '${e.category.label} · ${e.when}');
    }

    lines.add('');
    final dw = await duty.getWeek();
    lines.add('DUTY WEEK: ${dw.map((d) => '${d.day}:${d.personId}').join(' · ')}');
    final cl = await duty.getChecklist();
    final done = cl.where((c) => c.done).length;
    lines.add('CHECKLIST: $done/${cl.length} done');

    lines.add('');
    final docs = await knowledge.getDocs();
    lines.add('DOCS: ${docs.length}');
    for (final d in docs) {
      lines.add('  ${d.featured ? '★ ' : ''}${d.title} (${d.tag}, ${d.readTime})');
    }

    lines.add('');
    final prefs = await settings.getNotifPrefs();
    lines.add('NOTIF PREFS:');
    for (final p in prefs) {
      lines.add('  ${p.enabled ? '✓' : '☐'} ${p.label}');
    }

    return lines;
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
        title: Text('Seed Debug', style: AppType.h3(c)),
      ),
      body: FutureBuilder<List<String>>(
        future: _dump(),
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(
                child: Text('${snap.error}', style: AppType.body(c)),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPad),
            itemCount: snap.data!.length,
            itemBuilder: (context, i) => Text(
              snap.data![i],
              style: AppType.number(13, c).copyWith(height: 1.6),
            ),
          );
        },
      ),
    );
  }
}
