import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/enums.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class LeaderboardState {
  final LbFilter filter;
  final List<LeaderboardEntry> entries;
  final String? meId;
  final bool loading;

  const LeaderboardState({
    this.filter = LbFilter.allTime,
    this.entries = const [],
    this.meId,
    this.loading = true,
  });

  LeaderboardState copyWith({
    LbFilter? filter,
    List<LeaderboardEntry>? entries,
    String? meId,
    bool? loading,
  }) => LeaderboardState(
    filter: filter ?? this.filter,
    entries: entries ?? this.entries,
    meId: meId ?? this.meId,
    loading: loading ?? this.loading,
  );
}

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository _repo;

  LeaderboardCubit(this._repo) : super(const LeaderboardState()) {
    _load(LbFilter.allTime);
  }

  Future<void> setFilter(LbFilter filter) async {
    if (filter == state.filter && !state.loading) return;
    await _load(filter);
  }

  Future<void> _load(LbFilter filter) async {
    emit(state.copyWith(filter: filter, loading: true));
    final entries = await _repo.getLeaderboard(filter);
    if (isClosed) return;
    emit(state.copyWith(
      entries: entries,
      meId: _repo.currentUserId,
      loading: false,
    ));
  }
}
