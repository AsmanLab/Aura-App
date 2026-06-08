import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/models/enums.dart';

/// 4-step award draft (commands/06 §6.4). Steps: 0 intern · 1 category ·
/// 2 points · 3 confirm.
class AwardState extends Equatable {
  final int step;
  final List<Person> interns;
  final String? internId;
  final AuraCategory? category;
  final int points;
  final String comment;
  final bool attachLinear;
  final bool submitted;

  const AwardState({
    this.step = 0,
    this.interns = const [],
    this.internId,
    this.category,
    this.points = 25,
    this.comment = '',
    this.attachLinear = false,
    this.submitted = false,
  });

  bool get canContinue => switch (step) {
    0 => internId != null,
    1 => category != null,
    _ => true,
  };

  Person? get intern =>
      internId == null ? null : interns.firstWhere((p) => p.id == internId);

  AwardState copyWith({
    int? step,
    List<Person>? interns,
    String? internId,
    AuraCategory? category,
    int? points,
    String? comment,
    bool? attachLinear,
    bool? submitted,
  }) => AwardState(
    step: step ?? this.step,
    interns: interns ?? this.interns,
    internId: internId ?? this.internId,
    category: category ?? this.category,
    points: points ?? this.points,
    comment: comment ?? this.comment,
    attachLinear: attachLinear ?? this.attachLinear,
    submitted: submitted ?? this.submitted,
  );

  @override
  List<Object?> get props => [
    step,
    interns,
    internId,
    category,
    points,
    comment,
    attachLinear,
    submitted,
  ];
}

class AwardCubit extends Cubit<AwardState> {
  final PeopleRepository _repo;

  AwardCubit(this._repo, {String? presetInternId})
      : super(const AwardState()) {
    _load(presetInternId);
  }

  Future<void> _load(String? presetInternId) async {
    final people = await _repo.getPeople();
    final interns = people.where((p) => p.role == Role.intern).toList();
    emit(state.copyWith(
      interns: interns,
      internId: presetInternId,
      step: presetInternId != null ? 1 : 0,
    ));
  }

  void selectIntern(String id) =>
      emit(state.copyWith(internId: id, step: 1));
  void selectCategory(AuraCategory cat) =>
      emit(state.copyWith(category: cat));
  void setPoints(int pts) => emit(state.copyWith(points: pts));
  void setComment(String c) => emit(state.copyWith(comment: c));
  void toggleLinear(bool v) => emit(state.copyWith(attachLinear: v));

  void next() {
    if (state.canContinue && state.step < 3) {
      emit(state.copyWith(step: state.step + 1));
    }
  }

  void back() {
    if (state.step > 0) emit(state.copyWith(step: state.step - 1));
  }

  /// Seed-only: no write. Real impl awards via repository in a later stage.
  void submit() => emit(state.copyWith(submitted: true));
}
