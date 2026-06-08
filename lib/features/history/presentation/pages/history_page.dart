import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/core/widgets/app_card.dart';
import 'package:aura_app/core/widgets/aura_transaction_tile.dart';
import 'package:aura_app/core/widgets/category_chip.dart';
import 'package:aura_app/core/widgets/skeleton.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/features/profile/domain/repositories/profile_repository.dart';

/// Full aura history — filter by category, grouped by date.
class HistoryPage extends StatefulWidget {
  /// Whose history. Null = the signed-in user.
  final String? userId;
  const HistoryPage({super.key, this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  AuraCategory? _filter; // null = all
  bool _showCalendar = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late final String? _uid =
      widget.userId ?? sl<AuthRepository>().currentUser?.id;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        title: Text('History', style: AppType.h3(c)),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<AuraTransaction>>(
          future: _uid == null
              ? Future.value(const [])
              : sl<ProfileRepository>().getHistory(_uid),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const PageSkeleton();
            }
            final all = snap.data ?? const <AuraTransaction>[];
            final byCategory = _filter == null
                ? all
                : all.where((t) => t.category == _filter!.name).toList();
            // Period filter: only transactions in the selected month.
            final filtered = byCategory
                .where((t) =>
                    t.timestamp.year == _month.year &&
                    t.timestamp.month == _month.month)
                .toList();
            final groups = _groupByDay(filtered);

            return Column(
              children: [
                _FilterBar(
                  selected: _filter,
                  onSelect: (cat) => setState(() => _filter = cat),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPad,
                      AppSpacing.s2,
                      AppSpacing.screenPad,
                      120,
                    ),
                    children: [
                      _PeriodBar(
                        month: _month,
                        open: _showCalendar,
                        onPrev: () => setState(() => _month =
                            DateTime(_month.year, _month.month - 1)),
                        onNext: () => setState(() => _month =
                            DateTime(_month.year, _month.month + 1)),
                        onToggle: () =>
                            setState(() => _showCalendar = !_showCalendar),
                      ),
                      if (_showCalendar)
                        _MonthCalendar(month: _month, txns: filtered),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s8),
                          child: Center(
                            child: Text('No aura yet.',
                                style: AppType.bodyDim(c)),
                          ),
                        )
                      else
                        for (final g in groups) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.s5,
                              bottom: AppSpacing.s2,
                            ),
                            child: Text(g.label, style: AppType.label(c)),
                          ),
                          AppCard.flush(
                            child: Column(
                              children: [
                                for (var i = 0; i < g.items.length; i++)
                                  AuraTransactionTile(
                                    txn: g.items[i],
                                    divider: i != g.items.length - 1,
                                  ),
                              ],
                            ),
                          ),
                        ],
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

class _DayGroup {
  final String label;
  final List<AuraTransaction> items;
  _DayGroup(this.label, this.items);
}

List<_DayGroup> _groupByDay(List<AuraTransaction> txns) {
  final groups = <String, List<AuraTransaction>>{};
  for (final t in txns) {
    groups.putIfAbsent(_dayLabel(t.timestamp), () => []).add(t);
  }
  return groups.entries.map((e) => _DayGroup(e.key, e.value)).toList();
}

String _dayLabel(DateTime t) {
  final now = DateTime.now();
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat('EEEE').format(t); // weekday
  return DateFormat('MMMM d, y').format(t);
}

class _PeriodBar extends StatelessWidget {
  final DateTime month;
  final bool open;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToggle;

  const _PeriodBar({
    required this.month,
    required this.open,
    required this.onPrev,
    required this.onNext,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            // Centered period with prev/next.
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onPrev,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.chevron_left, color: c.textDim),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Text(DateFormat('MMMM y').format(month),
                      style: AppType.h3(c)),
                  const SizedBox(width: AppSpacing.s3),
                  IconButton(
                    onPressed: onNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.chevron_right, color: c.textDim),
                  ),
                ],
              ),
            ),
            // Calendar toggle pinned right.
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  Icons.calendar_month,
                  color: open ? c.accentSolid : c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Month grid with per-day net aura (green if +, red if −).
class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final List<AuraTransaction> txns;

  const _MonthCalendar({required this.month, required this.txns});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    // Net points per day-of-month for this month.
    final net = <int, int>{};
    for (final t in txns) {
      if (t.timestamp.year == month.year &&
          t.timestamp.month == month.month) {
        net.update(t.timestamp.day, (v) => v + t.points,
            ifAbsent: () => t.points);
      }
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final leading = firstWeekday - 1;
    final cells = <int?>[
      ...List.filled(leading, null),
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(w, style: AppType.label(c)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          for (var i = 0; i < cells.length; i += 7)
            Row(
              children: [
                for (var j = i; j < i + 7; j++)
                  Expanded(child: _DayCell(day: cells[j], net: net[cells[j]])),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int? day;
  final int? net;
  const _DayCell({required this.day, required this.net});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    if (day == null) return const SizedBox(height: 46);

    final has = net != null && net != 0;
    final color = net == null
        ? null
        : net! > 0
            ? c.success
            : net! < 0
                ? c.heart
                : c.textDim;

    return Container(
      height: 46,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: has ? color!.withValues(alpha: 0.12) : null,
        borderRadius: BorderRadius.circular(AppSpacing.rSm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: AppType.sm(c).copyWith(color: has ? color : c.textDim),
          ),
          if (has)
            Text(
              '${net! > 0 ? '+' : ''}$net',
              style: AppType.label(c).copyWith(color: color),
            ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AuraCategory? selected;
  final ValueChanged<AuraCategory?> onSelect;
  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
        children: [
          _AllChip(
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: AppSpacing.s2),
          for (final cat in AuraCategory.values) ...[
            CategoryChip(
              cat: cat,
              selected: selected == cat,
              onTap: () => onSelect(cat),
            ),
            const SizedBox(width: AppSpacing.s2),
          ],
        ],
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _AllChip({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? c.accentSolid : c.surface2,
            borderRadius: BorderRadius.circular(AppSpacing.rChip),
            border: Border.all(color: selected ? c.accentSolid : c.border),
          ),
          child: Text(
            'All',
            style: AppType.sm(c).copyWith(
              color: selected ? Colors.white : c.textDim,
            ),
          ),
        ),
      ),
    );
  }
}
