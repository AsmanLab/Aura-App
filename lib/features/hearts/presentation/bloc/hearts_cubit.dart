import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/user_model.dart';
import '../../domain/repositories/hearts_repository.dart';

class HeartsState extends Equatable {
  final bool loading;
  final bool canAward;
  final List<UserModel> recipients;
  final String? recipientId;
  final String comment;
  final bool submitting;
  final bool submitted;
  final String? error;

  const HeartsState({
    this.loading = true,
    this.canAward = false,
    this.recipients = const [],
    this.recipientId,
    this.comment = '',
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  UserModel? get recipient => recipientId == null
      ? null
      : recipients.cast<UserModel?>().firstWhere(
            (u) => u?.id == recipientId,
            orElse: () => null,
          );

  HeartsState copyWith({
    bool? loading,
    bool? canAward,
    List<UserModel>? recipients,
    String? recipientId,
    String? comment,
    bool? submitting,
    bool? submitted,
    String? error,
  }) => HeartsState(
    loading: loading ?? this.loading,
    canAward: canAward ?? this.canAward,
    recipients: recipients ?? this.recipients,
    recipientId: recipientId ?? this.recipientId,
    comment: comment ?? this.comment,
    submitting: submitting ?? this.submitting,
    submitted: submitted ?? this.submitted,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading,
    canAward,
    recipients,
    recipientId,
    comment,
    submitting,
    submitted,
    error,
  ];
}

class HeartsCubit extends Cubit<HeartsState> {
  final HeartsRepository _repo;

  HeartsCubit(this._repo, {String? presetRecipientId})
      : super(const HeartsState()) {
    _load(presetRecipientId);
  }

  Future<void> _load(String? presetId) async {
    final me = await _repo.getMe();
    final recipients = await _repo.getRecipients();
    if (isClosed) return;
    final hasPreset =
        presetId != null && recipients.any((u) => u.id == presetId);
    emit(state.copyWith(
      loading: false,
      canAward: me?.canAward ?? false,
      recipients: recipients,
      recipientId: hasPreset ? presetId : null,
    ));
  }

  void selectRecipient(String id) =>
      emit(state.copyWith(recipientId: id, comment: ''));
  void clearRecipient() => emit(state.copyWith(recipientId: null, comment: ''));
  void setComment(String c) => emit(state.copyWith(comment: c));

  /// delta: +1 add, -1 remove.
  Future<void> submit(int delta) async {
    final r = state.recipient;
    if (state.submitting || r == null) return;
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _repo.changeHeart(
        toUserId: r.id,
        delta: delta,
        comment: state.comment,
      );
      if (isClosed) return;
      emit(state.copyWith(submitting: false, submitted: true));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
