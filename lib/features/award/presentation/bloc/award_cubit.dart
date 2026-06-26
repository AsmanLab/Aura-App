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

/// 4-step award flow. Steps: 0 recipients · 1 category · 2 points · 3 confirm.
class AwardState extends Equatable {
  final int step;
  final bool loading;
  final bool canAward;
  final bool isMentor;
  final List<UserModel> recipients;
  final Set<String> recipientIds;
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
    this.recipientIds = const {},
    this.category,
    this.points = 1,
    this.comment = '',
    this.usedToday = 0,
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  int get minPoints => isMentor ? -10 : -1;
  int get maxPoints => isMentor ? 10 : 1;

  /// Awards left today (non-mentors). null = unlimited (mentor).
  int? get remainingToday =>
      isMentor ? null : (auraDailyLimit - usedToday).clamp(0, auraDailyLimit);

  bool get quotaReached => remainingToday != null && remainingToday! <= 0;

  bool get canContinue => switch (step) {
    0 => recipientIds.isNotEmpty,
    1 => true,
    _ => true,
  };

  List<UserModel> get selectedRecipients =>
      recipients.where((u) => recipientIds.contains(u.id)).toList();

  AwardState copyWith({
    int? step,
    bool? loading,
    bool? canAward,
    bool? isMentor,
    List<UserModel>? recipients,
    Set<String>? recipientIds,
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
    recipientIds: recipientIds ?? this.recipientIds,
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
    step, loading, canAward, isMentor, recipients,
    recipientIds, category, points, comment,
    usedToday, submitting, submitted, error,
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
    final today = DateUtils.currentDayKeyUtc();
    final usedToday = (me != null && me.awardDay == today) ? me.awardCount : 0;
    emit(state.copyWith(
      loading: false,
      canAward: me != null,
      isMentor: me?.canAward ?? false,
      usedToday: usedToday,
      recipients: recipients,
      recipientIds: hasPreset ? {presetId} : const {},
      step: hasPreset ? 1 : 0,
    ));
  }

  /// Mentors: toggle multi-select. Non-mentors: single select + auto-advance.
  void toggleRecipient(String id) {
    if (state.isMentor) {
      final ids = Set<String>.from(state.recipientIds);
      if (ids.contains(id)) {
        ids.remove(id);
      } else {
        ids.add(id);
      }
      emit(state.copyWith(recipientIds: ids));
    } else {
      emit(state.copyWith(recipientIds: {id}, step: 1));
    }
  }

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
    if (state.submitting || state.recipientIds.isEmpty) return;
    if (state.quotaReached) {
      emit(state.copyWith(
        error: "You've reached your daily limit of $auraDailyLimit aura. "
            'Try again tomorrow.',
      ));
      return;
    }
    emit(state.copyWith(submitting: true, error: null));
    var awarded = 0;
    try {
      for (final id in state.recipientIds) {
        await _repo.award(
          toUserId: id,
          points: state.points,
          comment: state.comment,
          category: state.category,
        );
        awarded++;
      }
      emit(state.copyWith(
        submitting: false,
        submitted: true,
        usedToday: state.usedToday + awarded,
      ));
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
