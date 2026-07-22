import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/domain/entities/duty_day.dart';
import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/avatar.dart';
import 'package:aura_app/core/widgets/section_label.dart';
import 'package:aura_app/l10n/generated/app_localizations.dart';
import '../bloc/duty_cubit.dart';

class DutyPage extends StatefulWidget {
  const DutyPage({super.key});

  @override
  State<DutyPage> createState() => _DutyPageState();
}

class _DutyPageState extends State<DutyPage> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: context.read<DutyCubit>().state.shiftNote,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _addTask() {
    final s = S.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).extension<AppColors>()!.surface,
        title: Text(s.addTask, style: AppType.h3(Theme.of(context).extension<AppColors>()!)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: s.taskName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<DutyCubit>().addChecklistItem(text);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.addTask),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<Map<String, Person>>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'intern')
              .get()
              .then((snap) {
            final byId = <String, Person>{};
            for (final doc in snap.docs) {
              final user = UserModel.fromMap(doc.data(), doc.id);
              byId[user.id] = user.toPerson();
            }
            return byId;
          }),
          builder: (context, peopleSnap) {
            if (!peopleSnap.hasData) {
              return const PageSkeleton();
            }
            final byId = peopleSnap.data!;
            return BlocBuilder<DutyCubit, DutyState>(
              builder: (context, state) {
                if (state.loading) {
                  return const PageSkeleton();
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
                        Text(s.duty, style: AppType.h1(c)),
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
                                s.onDutyNow,
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
                    SectionLabel(s.thisWeek),
                    Row(
                      children: [
                        for (final d in state.week)
                          Expanded(child: _DayCell(day: d, byId: byId)),
                      ],
                    ),
                    SectionLabel(s.myShift),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 18, color: c.accent1),
                              const SizedBox(width: AppSpacing.s2),
                              Text(
                                DateFormat('EEEE, MMM d').format(DateTime.now()),
                                style: AppType.h3(c),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 18, color: c.accent1),
                              const SizedBox(width: AppSpacing.s2),
                              Text('10:00 — 18:00', style: AppType.body(c)),
                              const SizedBox(width: AppSpacing.s2),
                              Icon(Icons.location_on_rounded, size: 16, color: c.textFaint),
                              const SizedBox(width: AppSpacing.s1),
                              Text('Bishkek', style: AppType.sm(c)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.checklist(state.done, state.checklist.length),
                                  style: AppType.label(c),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addTask,
                                icon: Icon(Icons.add_rounded, size: 18),
                                label: Text(s.addTask),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          for (final item in state.checklist)
                            _ChecklistRow(item: item),
                          const SizedBox(height: AppSpacing.s4),
                          Row(
                            children: [
                              Icon(Icons.note_rounded, size: 18, color: c.accent1),
                              const SizedBox(width: AppSpacing.s2),
                              Text(s.handoffNote, style: AppType.label(c)),
                              const Spacer(),
                              if (state.shiftNote.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    _noteController.clear();
                                    context.read<DutyCubit>().clearShiftNote();
                                  },
                                  icon: Icon(Icons.clear_rounded, size: 18, color: c.textFaint),
                                  tooltip: s.cancel,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          TextField(
                            controller: _noteController,
                            maxLines: 3,
                            style: AppType.body(c),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: c.surface2,
                              hintText: s.handoffHint,
                              hintStyle: AppType.bodyDim(c),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.rSm),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (v) =>
                                context.read<DutyCubit>().updateShiftNote(v),
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
            color: day.isToday ? Colors.transparent : c.border,
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
            IconButton(
              onPressed: () => context.read<DutyCubit>().deleteChecklistItem(item.id),
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.textFaint),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
