import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Reads users and aggregates this month's aura for the leaderboard.
abstract class LeaderboardRemoteDataSource {
  Stream<List<UserModel>> watchUsers();

  /// Sum of aura points received per user since the start of this month.
  Stream<Map<String, int>> watchMonthlyTotals();
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final FirebaseFirestore? _db;
  LeaderboardRemoteDataSourceImpl(this._db);

  @override
  Stream<List<UserModel>> watchUsers() {
    return _db!
        .collection('users')
        .limit(200)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Stream<Map<String, int>> watchMonthlyTotals() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    return _db!
        .collection('aura_transactions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .limit(1000)
        .snapshots()
        .map((snap) {
      final totals = <String, int>{};
      for (final d in snap.docs) {
        final t = AuraTransaction.fromMap(d.data(), d.id);
        totals.update(
          t.toUserId,
          (v) => v + t.points,
          ifAbsent: () => t.points,
        );
      }
      return totals;
    });
  }
}
