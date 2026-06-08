import 'package:firebase_auth/firebase_auth.dart';

import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remote;
  final FirebaseAuth _auth;

  LeaderboardRepositoryImpl(this._remote, this._auth);

  @override
  Future<List<UserModel>> getLeaderboard(LbFilter filter) {
    final field =
        filter == LbFilter.week ? 'currentWeekAura' : 'totalAura';
    return _remote.fetch(field);
  }

  @override
  String? get currentUserId => _auth.currentUser?.uid;
}
