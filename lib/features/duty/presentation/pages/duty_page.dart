import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/duty_day.dart';
import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import '../bloc/duty_cubit.dart';

class DutyPage extends StatelessWidget {
  const DutyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, Person>>(
          future: sl<PeopleRepository>().getPeople().then(
                (ps) => {for (final p in ps) p.id: p},
              ),
          builder: (context, peopleSnap) {
            if (!peopleSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final byId = peopleSnap.data!;
            return BlocBuilder<DutyCubit, DutyState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final onDuty = state.week.firstWhere(
                  (d) => d.isToday,
                  orElse: () => state.week.first,
                );
                final onDutyPerson = byId[onDuty.personId];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPad,
                    AppSpacing.s4,
                    AppSpacing.screenPad,
                    120,
                  ),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => context.pop(),
                          icon: Icon(Icons.arrow_back, color: c.text),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Text('Duty', style: AppType.h1(c)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    AppCard(
                      color: c.success.withValues(alpha: 0.08),
                      child: Row(
                        children: [
                          if (onDutyPerson != null)
                            Avatar(
                              id: onDutyPerson.id,
                              name: onDutyPerson.name,
                              size: 48,
                            ),
                          const SizedBox(width: AppSpacing.s4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ON DUTY NOW',
                                style: AppType.label(c)
                                    .copyWith(color: c.success),
                              ),
                              Text(onDutyPerson?.name ?? '—',
                                  style: AppType.h3(c)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SectionLabel('This week'),
                    Row(
                      children: [
                        for (final d in state.week)
                          Expanded(child: _DayCell(day: d, byId: byId)),
                      ],
                    ),
                    const SectionLabel('My shift'),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Wednesday, Jun 3', style: AppType.h3(c)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('Active',
                                    style: AppType.sm(c)
                                        .copyWith(color: c.success)),
                              ),
                            ],
                          ),
                          Text('10:00 — 18:00 · Bishkek', style: AppType.sm(c)),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            'Checklist · ${state.done}/${state.checklist.length}',
                            style: AppType.label(c),
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          for (final item in state.checklist)
                            _ChecklistRow(item: item),
                          const SizedBox(height: AppSpacing.s4),
                          Text('Handoff note', style: AppType.label(c)),
                          const SizedBox(height: AppSpacing.s2),
                          TextField(
                            maxLines: 3,
                            style: AppType.body(c),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: c.surface2,
                              hintText: 'What should the next shift know?',
                              hintStyle: AppType.bodyDim(c),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.rSm),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DutyDay day;
  final Map<String, Person> byId;
  const _DayCell({required this.day, required this.byId});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final person = byId[day.personId];
    final isMine = person?.isYou ?? false;
    return GestureDetector(
      onTap: () => context.push('/aura/profile/${day.personId}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        decoration: BoxDecoration(
          gradient: day.isToday
              ? LinearGradient(colors: [c.accent1, c.accent2])
              : null,
          color: day.isToday ? null : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.rSm),
          border: Border.all(
            color: !day.isToday && isMine ? c.accentSolid : c.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              day.day,
              style: AppType.label(c).copyWith(
                color: day.isToday ? Colors.white : c.textFaint,
              ),
            ),
            Text(
              day.date,
              style: AppType.number(14, c).copyWith(
                color: day.isToday ? Colors.white : c.text,
              ),
            ),
            const SizedBox(height: 4),
            if (person != null)
              Avatar(id: person.id, name: person.name, size: 26),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final ChecklistItem item;
  const _ChecklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: () => context.read<DutyCubit>().toggle(item.id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: item.done
                    ? LinearGradient(colors: [c.accent1, c.accent2])
                    : null,
                borderRadius: BorderRadius.circular(7),
                border: item.done ? null : Border.all(color: c.borderStrong),
              ),
              child: item.done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                item.text,
                style: AppType.body(c).copyWith(
                  color: item.done ? c.textFaint : c.text,
                  decoration:
                      item.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
