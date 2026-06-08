import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Reads a user's profile + received-aura history.
abstract class ProfileRemoteDataSource {
  Future<UserModel?> getUser(String id);
  Future<List<AuraTransaction>> getHistory(String userId);
  Future<List<HeartTransaction>> getHeartHistory(String userId);

  /// Realtime: emits on every change to the user's received-aura history.
  Stream<List<AuraTransaction>> watchHistory(String userId);

  /// Realtime: emits on every change to the user's doc (aura totals etc).
  Stream<UserModel?> watchUser(String id);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _db;
  ProfileRemoteDataSourceImpl(this._db);

  @override
  Future<UserModel?> getUser(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    return doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null;
  }

  @override
  Future<List<AuraTransaction>> getHistory(String userId) async {
    // Single `where` (no composite index needed); sort in memory.
    final snap = await _db
        .collection('aura_transactions')
        .where('toUserId', isEqualTo: userId)
        .limit(100)
        .get();
    final txns = snap.docs
        .map((d) => AuraTransaction.fromMap(d.data(), d.id))
        .toList();
    txns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return txns;
  }

  @override
  Future<List<HeartTransaction>> getHeartHistory(String userId) async {
    final snap = await _db
        .collection('hearts_transactions')
        .where('toUserId', isEqualTo: userId)
        .limit(100)
        .get();
    final txns = snap.docs
        .map((d) => HeartTransaction.fromMap(d.data(), d.id))
        .toList();
    txns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return txns;
  }

  @override
  Stream<List<AuraTransaction>> watchHistory(String userId) {
    return _db
        .collection('aura_transactions')
        .where('toUserId', isEqualTo: userId)
        .limit(100)
        .snapshots()
        .map((snap) {
          final txns = snap.docs
              .map((d) => AuraTransaction.fromMap(d.data(), d.id))
              .toList();
          txns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return txns;
        });
  }

  @override
  Stream<UserModel?> watchUser(String id) {
    return _db.collection('users').doc(id).snapshots().map(
          (d) => d.exists ? UserModel.fromMap(d.data()!, d.id) : null,
        );
  }
}
