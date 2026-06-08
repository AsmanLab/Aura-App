import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';
import '../../domain/repositories/leaderboard_repository.dart';

class LeaderboardState extends Equatable {
  final LbFilter filter;
  final List<UserModel> users;
  final String? meId;
  final bool loading;

  const LeaderboardState({
    this.filter = LbFilter.allTime,
    this.users = const [],
    this.meId,
    this.loading = true,
  });

  /// Score shown for the active period.
  int scoreOf(UserModel u) =>
      filter == LbFilter.week ? u.currentWeekAura : u.totalAura;

  LeaderboardState copyWith({
    LbFilter? filter,
    List<UserModel>? users,
    String? meId,
    bool? loading,
  }) => LeaderboardState(
    filter: filter ?? this.filter,
    users: users ?? this.users,
    meId: meId ?? this.meId,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [filter, users, meId, loading];
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
    final users = await _repo.getLeaderboard(filter);
    if (isClosed) return;
    emit(state.copyWith(
      users: users,
      meId: _repo.currentUserId,
      loading: false,
    ));
  }
}
