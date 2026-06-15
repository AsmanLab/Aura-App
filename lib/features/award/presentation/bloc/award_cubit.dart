import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import '../../domain/repositories/award_repository.dart';

/// How often a non-mentor may give aura. Tune here (mirrored in firestore.rules
/// as `duration.value(5, 'm')`).
const awardCooldown = Duration(minutes: 5);

/// 4-step award flow (commands/06 §6.4). Steps: 0 recipient · 1 category ·
/// 2 points · 3 confirm. Writes to Firebase on submit.
class AwardState extends Equatable {
  final int step;
  final bool loading;
  final bool canAward; // signed in → allowed to give aura at all
  final bool isMentor; // mentor/fullTime/admin → wide range, no cooldown
  final List<UserModel> recipients;
  final String? recipientId;
  final AuraCategory? category;
  final int points;
  final String comment;

  /// Giver's last award time (cooldown anchor for non-mentors).
  final DateTime? lastAwardAt;

  final bool submitting;
  final bool submitted;
  final String? error;

  const AwardState({
    this.step = 0,
    this.loading = true,
    this.canAward = false,
    this.isMentor = false,
    this.recipients = const [],
    this.recipientId,
    this.category,
    this.points = 1,
    this.comment = '',
    this.lastAwardAt,
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  // Non-mentors are capped at ±1; mentors keep the wide range.
  int get minPoints => isMentor ? -10 : -1;
  int get maxPoints => isMentor ? 10 : 1;

  /// When the giver may award again (null = no cooldown / ready now).
  DateTime? get cooldownUntil =>
      (isMentor || lastAwardAt == null) ? null : lastAwardAt!.add(awardCooldown);

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
    bool? isMentor,
    List<UserModel>? recipients,
    String? recipientId,
    AuraCategory? category,
    int? points,
    String? comment,
    DateTime? lastAwardAt,
    bool? submitting,
    bool? submitted,
    String? error,
  }) => AwardState(
    step: step ?? this.step,
    loading: loading ?? this.loading,
    canAward: canAward ?? this.canAward,
    isMentor: isMentor ?? this.isMentor,
    recipients: recipients ?? this.recipients,
    recipientId: recipientId ?? this.recipientId,
    category: category ?? this.category,
    points: points ?? this.points,
    comment: comment ?? this.comment,
    lastAwardAt: lastAwardAt ?? this.lastAwardAt,
    submitting: submitting ?? this.submitting,
    submitted: submitted ?? this.submitted,
    error: error,
  );

  @override
  List<Object?> get props => [
    step,
    loading,
    canAward,
    isMentor,
    recipients,
    recipientId,
    category,
    points,
    comment,
    lastAwardAt,
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
      isMentor: me?.canAward ?? false,
      lastAwardAt: me?.lastAwardAt,
      recipients: recipients,
      recipientId: hasPreset ? presetId : null,
      step: hasPreset ? 1 : 0,
    ));
  }

  void selectRecipient(String id) =>
      emit(state.copyWith(recipientId: id, step: 1));
  void selectCategory(AuraCategory cat) =>
      emit(state.copyWith(category: cat));

  void setPoints(int pts) => emit(
        state.copyWith(points: pts.clamp(state.minPoints, state.maxPoints)),
      );
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
    // Client-side cooldown guard (server enforces too via firestore.rules).
    final until = state.cooldownUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      final secs = until.difference(DateTime.now()).inSeconds;
      emit(state.copyWith(
        error: 'Slow down — you can give aura again in ${_fmt(secs)}.',
      ));
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

  static String _fmt(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }
}
