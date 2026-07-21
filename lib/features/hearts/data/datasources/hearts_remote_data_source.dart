import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Reads interns + applies a heart change atomically (clamped 0..max).
abstract class HeartsRemoteDataSource {
  Future<List<UserModel>> getInterns();
  Future<void> changeHeart(HeartTransaction txn);
}

class HeartsRemoteDataSourceImpl implements HeartsRemoteDataSource {
  final FirebaseFirestore? _db;
  HeartsRemoteDataSourceImpl(this._db);

  @override
  Future<List<UserModel>> getInterns() async {
    final snap = await _db!
        .collection('users')
        .where('role', isEqualTo: 'intern')
        .get();
    final users =
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    users.sort((a, b) => a.displayName.compareTo(b.displayName));
    return users;
  }

  @override
  Future<void> changeHeart(HeartTransaction txn) async {
    final userRef = _db!.collection('users').doc(txn.toUserId);
    final txnRef = _db.collection('hearts_transactions').doc(txn.id);
    _db.runTransaction((t) async {
      final snap = await t.get(userRef);
      final current = (snap.data()?['hearts'] ?? UserModel.maxHearts) as int;
      final next = current + txn.delta;
      if (next < 0 || next > UserModel.maxHearts) {
        throw Exception(
          txn.delta > 0 ? 'Already at max hearts' : 'No hearts to remove',
        );
      }
      t.update(userRef, {'hearts': next});
      t.set(txnRef, txn.toMap());
    });
  }
}
