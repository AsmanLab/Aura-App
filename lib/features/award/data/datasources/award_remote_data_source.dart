import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Award writes against Firestore: read recipients, write a transaction and
/// atomically increment the recipient's aura counters.
abstract class AwardRemoteDataSource {
  Future<List<UserModel>> getAllUsers();
  Future<void> award(AuraTransaction txn);
}

class AwardRemoteDataSourceImpl implements AwardRemoteDataSource {
  final FirebaseFirestore _db;
  AwardRemoteDataSourceImpl(this._db);

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    final users =
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    users.sort((a, b) => a.displayName.compareTo(b.displayName));
    return users;
  }

  @override
  Future<void> award(AuraTransaction txn) async {
    final batch = _db.batch();
    batch.set(
      _db.collection('aura_transactions').doc(txn.id),
      txn.toMap(),
    );
    batch.update(_db.collection('users').doc(txn.toUserId), {
      'currentWeekAura': FieldValue.increment(txn.points),
      'totalAura': FieldValue.increment(txn.points),
    });
    await batch.commit();
  }
}
