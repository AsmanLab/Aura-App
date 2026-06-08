import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/models/enums.dart';

class LeaderboardState extends Equatable {
  final LbFilter filter;
  final List<Person> ranked;
  final bool loading;

  const LeaderboardState({
    this.filter = LbFilter.allTime,
    this.ranked = const [],
    this.loading = true,
  });

  LeaderboardState copyWith({
    LbFilter? filter,
    List<Person>? ranked,
    bool? loading,
  }) => LeaderboardState(
    filter: filter ?? this.filter,
    ranked: ranked ?? this.ranked,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [filter, ranked, loading];
}

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final PeopleRepository _repo;

  LeaderboardCubit(this._repo) : super(const LeaderboardState()) {
    _load(LbFilter.allTime);
  }

  Future<void> setFilter(LbFilter filter) async {
    if (filter == state.filter && !state.loading) return;
    await _load(filter);
  }

  Future<void> _load(LbFilter filter) async {
    emit(state.copyWith(filter: filter, loading: true));
    final ranked = await _repo.getLeaderboard(filter);
    emit(state.copyWith(ranked: ranked, loading: false));
  }
}
