import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import '../../domain/repositories/award_repository.dart';

/// 4-step award flow (commands/06 §6.4). Steps: 0 recipient · 1 category ·
/// 2 points · 3 confirm. Writes to Firebase on submit.
class AwardState extends Equatable {
  final int step;
  final bool loading;
  final bool canAward; // giver is a mentor
  final List<UserModel> recipients;
  final String? recipientId;
  final AuraCategory? category;
  final int points;
  final String comment;
  final bool submitting;
  final bool submitted;
  final String? error;

  const AwardState({
    this.step = 0,
    this.loading = true,
    this.canAward = false,
    this.recipients = const [],
    this.recipientId,
    this.category,
    this.points = 1,
    this.comment = '',
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  bool get canContinue => switch (step) {
    0 => recipientId != null,
    1 => category != null,
    _ => true,
  };

  UserModel? get recipient => recipientId == null
      ? null
      : recipients.cast<UserModel?>().firstWhere(
            (u) => u?.id == recipientId,
            orElse: () => null,
          );

  AwardState copyWith({
    int? step,
    bool? loading,
    bool? canAward,
    List<UserModel>? recipients,
    String? recipientId,
    AuraCategory? category,
    int? points,
    String? comment,
    bool? submitting,
    bool? submitted,
    String? error,
  }) => AwardState(
    step: step ?? this.step,
    loading: loading ?? this.loading,
    canAward: canAward ?? this.canAward,
    recipients: recipients ?? this.recipients,
    recipientId: recipientId ?? this.recipientId,
    category: category ?? this.category,
    points: points ?? this.points,
    comment: comment ?? this.comment,
    submitting: submitting ?? this.submitting,
    submitted: submitted ?? this.submitted,
    error: error,
  );

  @override
  List<Object?> get props => [
    step,
    loading,
    canAward,
    recipients,
    recipientId,
    category,
    points,
    comment,
    submitting,
    submitted,
    error,
  ];
}

class AwardCubit extends Cubit<AwardState> {
  final AwardRepository _repo;

  AwardCubit(this._repo, {String? presetInternId})
      : super(const AwardState()) {
    _load(presetInternId);
  }

  Future<void> _load(String? presetId) async {
    final me = await _repo.getMe();
    final recipients = await _repo.getRecipients();
    if (isClosed) return;
    final hasPreset =
        presetId != null && recipients.any((u) => u.id == presetId);
    emit(state.copyWith(
      loading: false,
      // Anyone signed in can give aura (hearts stay mentor-only).
      canAward: me != null,
      recipients: recipients,
      recipientId: hasPreset ? presetId : null,
      step: hasPreset ? 1 : 0,
    ));
  }

  void selectRecipient(String id) =>
      emit(state.copyWith(recipientId: id, step: 1));
  void selectCategory(AuraCategory cat) =>
      emit(state.copyWith(category: cat));
  static const minPoints = -10;
  static const maxPoints = 10;

  void setPoints(int pts) =>
      emit(state.copyWith(points: pts.clamp(minPoints, maxPoints)));
  void setComment(String c) => emit(state.copyWith(comment: c));

  void next() {
    if (state.canContinue && state.step < 3) {
      emit(state.copyWith(step: state.step + 1));
    }
  }

  void back() {
    if (state.step > 0) emit(state.copyWith(step: state.step - 1));
  }

  Future<void> submit() async {
    if (state.submitting || state.recipientId == null ||
        state.category == null) {
      return;
    }
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _repo.award(
        toUserId: state.recipientId!,
        points: state.points,
        comment: state.comment,
        category: state.category!,
      );
      if (isClosed) return;
      emit(state.copyWith(submitting: false, submitted: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
