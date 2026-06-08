import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Reads a user's profile + received-aura history.
abstract class ProfileRemoteDataSource {
  Future<UserModel?> getUser(String id);
  Future<List<AuraTransaction>> getHistory(String userId);
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
}
