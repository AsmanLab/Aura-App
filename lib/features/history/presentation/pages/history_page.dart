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
import 'package:aura_app/l10n/generated/app_localizations.dart';

class HistoryPage extends StatefulWidget {
  final String? userId;
  const HistoryPage({super.key, this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  AuraCategory? _filter;
  bool _showCalendar = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late final String? _uid =
      widget.userId ?? sl<AuthRepository>().currentUser?.id;
  List<AuraTransaction> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_uid == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    final data = await sl<ProfileRepository>().getHistory(_uid!);
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  void _changeFilter(AuraCategory? cat) {
    setState(() => _filter = cat);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        elevation: 0,
        title: Text(s.history, style: AppType.h3(c)),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const PageSkeleton()
            : Column(
                children: [
                  _FilterBar(
                    selected: _filter,
                    onSelect: _changeFilter,
                  ),
                  Expanded(
                    child: _HistoryList(
                      allTransactions: _all,
                      category: _filter,
                      month: _month,
                      showCalendar: _showCalendar,
                      onToggleCalendar: () =>
                          setState(() => _showCalendar = !_showCalendar),
                      onPrev: () => setState(() => _month =
                          DateTime(_month.year, _month.month - 1)),
                      onNext: () => setState(() => _month =
                          DateTime(_month.year, _month.month + 1)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HistoryList extends StatefulWidget {
  final List<AuraTransaction> allTransactions;
  final AuraCategory? category;
  final DateTime month;
  final bool showCalendar;
  final VoidCallback onToggleCalendar;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _HistoryList({
    required this.allTransactions,
    required this.category,
    required this.month,
    required this.showCalendar,
    required this.onToggleCalendar,
    required this.onPrev,
    required this.onNext,
  });

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<AuraCategory?, double> _scrollOffsets = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffsets[widget.category] = _scrollController.offset;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category &&
        _scrollController.hasClients) {
      _scrollOffsets[oldWidget.category] = _scrollController.offset;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = S.of(context);
    final c = Theme.of(context).extension<AppColors>()!;

    final allInMonth = widget.allTransactions
        .where((t) =>
            t.timestamp.year == widget.month.year &&
            t.timestamp.month == widget.month.month)
        .toList();
    final allGroups = _groupByDay(context, allInMonth);

    final visibleSet = <String>{};
    for (final t in allInMonth) {
      if (widget.category != null && t.category != widget.category!.name) {
        continue;
      }
      visibleSet.add(_dayLabel(context, t.timestamp));
    }
    final isEmpty = visibleSet.isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final target = _scrollOffsets[widget.category] ?? 0.0;
        if ((_scrollController.offset - target).abs() > 0.5) {
          _scrollController.jumpTo(target);
        }
      }
    });

    return ListView.builder(
      key: const PageStorageKey<String>('history_list'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPad,
        AppSpacing.s2,
        AppSpacing.screenPad,
        120,
      ),
      itemCount: allGroups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _PeriodBar(
            month: widget.month,
            open: widget.showCalendar,
            onPrev: widget.onPrev,
            onNext: widget.onNext,
            onToggle: widget.onToggleCalendar,
          );
        }

        final g = allGroups[index - 1];
        final visible = visibleSet.contains(g.label);

        return Visibility(
          visible: visible,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s5, bottom: AppSpacing.s2),
                child: Text(g.label, style: AppType.label(c)),
              ),
              AppCard.flush(
                child: Column(
                  children: [
                    for (var i = 0; i < g.items.length; i++)
                      Offstage(
                        offstage: widget.category != null &&
                            g.items[i].category != widget.category!.name,
                        child: AuraTransactionTile(
                          txn: g.items[i],
                          divider: i != g.items.length - 1,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayGroup {
  final String label;
  final List<AuraTransaction> items;
  const _DayGroup(this.label, this.items);
}

String _dayLabel(BuildContext context, DateTime t) {
  final s = S.of(context);
  final now = DateTime.now();
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return s.today;
  if (diff == 1) return s.yesterday;
  if (diff < 7) return DateFormat('EEEE').format(t);
  return DateFormat('MMMM d, y').format(t);
}

List<_DayGroup> _groupByDay(BuildContext context, List<AuraTransaction> txns) {
  final groups = <String, List<AuraTransaction>>{};
  for (final t in txns) {
    groups.putIfAbsent(_dayLabel(context, t.timestamp), () => []).add(t);
  }
  return groups.entries.map((e) => _DayGroup(e.key, e.value)).toList();
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
                  Text(DateFormat('MMMM y').format(month), style: AppType.h3(c)),
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
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onToggle,
                icon: Icon(Icons.calendar_month, color: open ? c.accentSolid : c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime month;
  final List<AuraTransaction> txns;

  const _MonthCalendar({required this.month, required this.txns});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    final net = <int, int>{};
    for (final t in txns) {
      if (t.timestamp.year == month.year && t.timestamp.month == month.month) {
        net.update(t.timestamp.day, (v) => v + t.points, ifAbsent: () => t.points);
      }
    }

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
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
                Expanded(child: Center(child: Text(w, style: AppType.label(c)))),
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
          Text('$day', style: AppType.sm(c).copyWith(color: has ? color : c.textDim)),
          if (has)
            Text('${net! > 0 ? "+" : ""}$net', style: AppType.label(c).copyWith(color: color)),
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
          _AllChip(selected: selected == null, onTap: () => onSelect(null)),
          const SizedBox(width: AppSpacing.s2),
          for (final cat in AuraCategory.values) ...[
            CategoryChip(cat: cat, selected: selected == cat, onTap: () => onSelect(cat)),
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
    final s = S.of(context);
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
          child: Text(s.allFilter, style: AppType.sm(c).copyWith(color: selected ? Colors.white : c.textDim)),
        ),
      ),
    );
  }
}
