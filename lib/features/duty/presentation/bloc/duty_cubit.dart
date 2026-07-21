import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/domain/entities/duty_day.dart';
import 'package:aura_app/core/domain/repositories/duty_repository.dart';

class DutyState {
  final List<DutyDay> week;
  final List<ChecklistItem> checklist;
  final bool loading;
  final String shiftNote;
  final String myNotes;

  const DutyState({
    this.week = const [],
    this.checklist = const [],
    this.loading = true,
    this.shiftNote = '',
    this.myNotes = '',
  });

  int get done => checklist.where((c) => c.done).length;

  DutyState copyWith({
    List<DutyDay>? week,
    List<ChecklistItem>? checklist,
    bool? loading,
    String? shiftNote,
    String? myNotes,
  }) => DutyState(
    week: week ?? this.week,
    checklist: checklist ?? this.checklist,
    loading: loading ?? this.loading,
    shiftNote: shiftNote ?? this.shiftNote,
    myNotes: myNotes ?? this.myNotes,
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

  void updateShiftNote(String note) {
    emit(state.copyWith(shiftNote: note));
  }

  void updateMyNotes(String note) {
    emit(state.copyWith(myNotes: note));
  }

  void clearShiftNote() {
    emit(state.copyWith(shiftNote: ''));
  }

  void addChecklistItem(String text) {
    final newItem = ChecklistItem(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      done: false,
    );
    emit(state.copyWith(
      checklist: [...state.checklist, newItem],
    ));
  }

  void deleteChecklistItem(String id) {
    emit(state.copyWith(
      checklist: [
        for (final c in state.checklist)
          if (c.id != id) c,
      ],
    ));
  }
}
