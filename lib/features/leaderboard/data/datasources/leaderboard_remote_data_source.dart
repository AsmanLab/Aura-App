import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/user_model.dart';

/// Reads the `users` collection for the leaderboard.
abstract class LeaderboardRemoteDataSource {
  /// Top users ordered by [orderField] (e.g. 'totalAura' / 'currentWeekAura').
  Future<List<UserModel>> fetch(String orderField);
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final FirebaseFirestore _db;
  LeaderboardRemoteDataSourceImpl(this._db);

  @override
  Future<List<UserModel>> fetch(String orderField) async {
    final snap = await _db
        .collection('users')
        .orderBy(orderField, descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data(), d.id))
        .toList();
  }
}
