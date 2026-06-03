import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/aura_entry.dart';
import '../../../../shared/domain/entities/person.dart';
import '../../../../shared/domain/repositories/people_repository.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aura_progress_bar.dart';
import '../../../../shared/widgets/aura_value.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../../shared/widgets/hearts_row.dart';
import '../../../../shared/widgets/history_row.dart';
import '../../../../shared/widgets/section_label.dart';

typedef _HomeData = ({
  Person me,
  Person onDuty,
  Map<String, Person> byId,
  List<AuraEntry> history,
});

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<_HomeData> _load() async {
    final repo = sl<PeopleRepository>();
    final people = await repo.getPeople();
    return (
      me: await repo.getMe(),
      onDuty: await repo.getOnDuty(),
      byId: {for (final p in people) p.id: p},
      history: await repo.getHistory('aibek'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_HomeData>(
          future: _load(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = snap.data!;
            final trial = d.me.trial(DateTime(2026, 6, 3));
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPad,
                AppSpacing.s4,
                AppSpacing.screenPad,
                120,
              ),
              children: [
                // Greeting
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wednesday, Jun 3', style: AppType.sm(c)),
                          Text(
                            'Hi, ${d.me.name.split(' ').first}',
                            style: AppType.h1(c),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/aura/settings'),
                      icon: Icon(Icons.notifications_none, color: c.text),
                    ),
                  ],
                ),

                const SectionLabel('On duty now'),
                AppCard(
                  onTap: () => context.go('/aura/duty'),
                  child: Row(
                    children: [
                      Avatar(id: d.onDuty.id, name: d.onDuty.name, size: 52),
                      const SizedBox(width: AppSpacing.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.onDuty.name, style: AppType.h3(c)),
                            Text(d.onDuty.position, style: AppType.sm(c)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: c.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Live',
                                style: AppType.sm(c).copyWith(color: c.success),
                              ),
                            ],
                          ),
                          Text('until 6 PM', style: AppType.sm(c)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SectionLabel('My status'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Aura', style: AppType.sm(c)),
                      const SizedBox(height: AppSpacing.s2),
                      AuraValue(d.me.aura, size: 56),
                      const SizedBox(height: AppSpacing.s5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hearts', style: AppType.sm(c)),
                          Text('${d.me.hearts}/8', style: AppType.number(15, c)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      HeartsRow(count: d.me.hearts, size: 22),
                      if (trial != null) ...[
                        const SizedBox(height: AppSpacing.s5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Trial', style: AppType.sm(c)),
                            Text(
                              '${trial.daysLeft} days left',
                              style: AppType.number(15, c),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        AuraProgressBar(trial.pct * 100),
                      ],
                    ],
                  ),
                ),

                const SectionLabel('Recent Aura'),
                AppCard.flush(
                  child: Column(
                    children: [
                      for (var i = 0; i < 2 && i < d.history.length; i++)
                        HistoryRow(
                          entry: d.history[i],
                          giverId: d.history[i].byPersonId,
                          giverName:
                              d.byId[d.history[i].byPersonId]?.name ?? '?',
                          showDivider: i == 0,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
