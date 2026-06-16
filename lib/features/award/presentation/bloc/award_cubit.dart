import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/utils/date_utils.dart';
import 'package:aura_app/features/award/data/datasources/award_remote_data_source.dart'
    show auraDailyLimit;
import '../../domain/repositories/award_repository.dart';

/// Sentinel for copyWith so the optional category can be cleared with `null`.
const _noChange = Object();

/// 4-step award flow (commands/06 §6.4). Steps: 0 recipient · 1 category ·
/// 2 points · 3 confirm. Writes to Firebase on submit.
class AwardState extends Equatable {
  final int step;
  final bool loading;
  final bool canAward; // signed in → allowed to give aura at all
  final bool isMentor; // mentor/fullTime/admin → wide range, no daily limit
  final List<UserModel> recipients;
  final String? recipientId;
  final AuraCategory? category;
  final int points;
  final String comment;

  /// Awards the giver has already given today (non-mentors only).
  final int usedToday;

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
    this.usedToday = 0,
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  // Non-mentors are capped at ±1; mentors keep the wide range.
  int get minPoints => isMentor ? -10 : -1;
  int get maxPoints => isMentor ? 10 : 1;

  /// Awards left today (non-mentors). null = unlimited (mentor).
  int? get remainingToday =>
      isMentor ? null : (auraDailyLimit - usedToday).clamp(0, auraDailyLimit);

  bool get quotaReached => remainingToday != null && remainingToday! <= 0;

  bool get canContinue => switch (step) {
    0 => recipientId != null,
    1 => true, // category is optional
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
    // Sentinel so a null can clear the category (it's optional).
    Object? category = _noChange,
    int? points,
    String? comment,
    int? usedToday,
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
    category: category == _noChange ? this.category : category as AuraCategory?,
    points: points ?? this.points,
    comment: comment ?? this.comment,
    usedToday: usedToday ?? this.usedToday,
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
    usedToday,
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
    // Awards already given today (reset when the UTC day rolls over).
    final today = DateUtils.currentDayKeyUtc();
    final usedToday = (me != null && me.awardDay == today) ? me.awardCount : 0;
    emit(state.copyWith(
      loading: false,
      // Anyone signed in can give aura (hearts stay mentor-only).
      canAward: me != null,
      isMentor: me?.canAward ?? false,
      usedToday: usedToday,
      recipients: recipients,
      recipientId: hasPreset ? presetId : null,
      step: hasPreset ? 1 : 0,
    ));
  }

  void selectRecipient(String id) =>
      emit(state.copyWith(recipientId: id, step: 1));

  /// Tap a category to select it; tap the selected one again to clear it
  /// (categories are optional).
  void toggleCategory(AuraCategory cat) => emit(
        state.copyWith(category: state.category == cat ? null : cat),
      );

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
    // Category is optional; only the recipient is required.
    if (state.submitting || state.recipientId == null) return;
    // Client-side daily-quota guard (server enforces too via firestore.rules).
    if (state.quotaReached) {
      emit(state.copyWith(
        error: "You've reached your daily limit of $auraDailyLimit aura. "
            'Try again tomorrow.',
      ));
      return;
    }
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _repo.award(
        toUserId: state.recipientId!,
        points: state.points,
        comment: state.comment,
        category: state.category,
      );
      if (isClosed) return;
      // Count this award locally so the UI reflects the remaining quota.
      emit(state.copyWith(
        submitting: false,
        submitted: true,
        usedToday: state.usedToday + 1,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
