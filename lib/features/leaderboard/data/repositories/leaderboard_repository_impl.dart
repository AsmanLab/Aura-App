import 'package:firebase_auth/firebase_auth.dart';

import 'package:aura_app/core/models/enums.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remote;
  final FirebaseAuth _auth;

  LeaderboardRepositoryImpl(this._remote, this._auth);

  @override
  Future<List<LeaderboardEntry>> getLeaderboard(LbFilter filter) async {
    final users = await _remote.getUsers();

    List<LeaderboardEntry> entries;
    if (filter == LbFilter.month) {
      final monthly = await _remote.monthlyTotals();
      entries = users
          .map((u) => LeaderboardEntry(u, monthly[u.id] ?? 0))
          .toList();
    } else {
      entries = users
          .map((u) => LeaderboardEntry(
                u,
                filter == LbFilter.week ? u.currentWeekAura : u.totalAura,
              ))
          .toList();
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    return entries.take(50).toList();
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;
}
