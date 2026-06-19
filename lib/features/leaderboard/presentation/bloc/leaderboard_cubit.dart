import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/enums.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class LeaderboardState {
  final LbFilter filter;
  final List<LeaderboardEntry> entries;
  final String? meId;
  final bool loading;
  final String? errorMessage;

  const LeaderboardState({
    this.filter = LbFilter.allTime,
    this.entries = const [],
    this.meId,
    this.loading = true,
    this.errorMessage,
  });

  LeaderboardState copyWith({
    LbFilter? filter,
    List<LeaderboardEntry>? entries,
    String? meId,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) => LeaderboardState(
    filter: filter ?? this.filter,
    entries: entries ?? this.entries,
    meId: meId ?? this.meId,
    loading: loading ?? this.loading,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository _repo;
  StreamSubscription<List<LeaderboardEntry>>? _subscription;
  int _watchGeneration = 0;

  LeaderboardCubit(this._repo) : super(const LeaderboardState()) {
    _watch(LbFilter.allTime);
  }

  void setFilter(LbFilter filter) {
    if (filter == state.filter && !state.loading) return;
    _watch(filter);
  }

  void _watch(LbFilter filter) {
    final generation = ++_watchGeneration;
    _subscription?.cancel();
    emit(state.copyWith(filter: filter, loading: true, clearError: true));

    _subscription = _repo
        .watchLeaderboard(filter)
        .listen(
          (entries) {
            if (isClosed || generation != _watchGeneration) return;
            emit(
              state.copyWith(
                entries: entries,
                meId: _repo.currentUserId,
                loading: false,
                clearError: true,
              ),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            if (isClosed || generation != _watchGeneration) return;
            emit(
              state.copyWith(loading: false, errorMessage: error.toString()),
            );
          },
        );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
