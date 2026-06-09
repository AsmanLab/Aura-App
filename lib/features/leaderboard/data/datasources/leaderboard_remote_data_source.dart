import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Reads users + aggregates this month's aura for the leaderboard.
abstract class LeaderboardRemoteDataSource {
  Future<List<UserModel>> getUsers();

  /// Sum of aura points received per user since the start of this month.
  Future<Map<String, int>> monthlyTotals();
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final FirebaseFirestore _db;
  LeaderboardRemoteDataSourceImpl(this._db);

  @override
  Future<List<UserModel>> getUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
  }

  @override
  Future<Map<String, int>> monthlyTotals() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    // Single-field inequality on timestamp — no composite index needed.
    final snap = await _db
        .collection('aura_transactions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    final totals = <String, int>{};
    for (final d in snap.docs) {
      final t = AuraTransaction.fromMap(d.data(), d.id);
      totals.update(t.toUserId, (v) => v + t.points, ifAbsent: () => t.points);
    }
    return totals;
  }
}
