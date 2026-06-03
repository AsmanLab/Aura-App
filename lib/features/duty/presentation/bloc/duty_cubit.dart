import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/domain/entities/duty_day.dart';
import '../../../../shared/domain/repositories/duty_repository.dart';

class DutyState {
  final List<DutyDay> week;
  final List<ChecklistItem> checklist;
  final bool loading;

  const DutyState({
    this.week = const [],
    this.checklist = const [],
    this.loading = true,
  });

  int get done => checklist.where((c) => c.done).length;

  DutyState copyWith({
    List<DutyDay>? week,
    List<ChecklistItem>? checklist,
    bool? loading,
  }) => DutyState(
    week: week ?? this.week,
    checklist: checklist ?? this.checklist,
    loading: loading ?? this.loading,
  );
}

class DutyCubit extends Cubit<DutyState> {
  final DutyRepository _repo;

  DutyCubit(this._repo) : super(const DutyState()) {
    _load();
  }

  Future<void> _load() async {
    final week = await _repo.getWeek();
    final checklist = await _repo.getChecklist();
    emit(DutyState(week: week, checklist: checklist, loading: false));
  }

  void toggle(String id) {
    emit(state.copyWith(
      checklist: [
        for (final c in state.checklist)
          if (c.id == id) c.copyWith(done: !c.done) else c,
      ],
    ));
  }
}
