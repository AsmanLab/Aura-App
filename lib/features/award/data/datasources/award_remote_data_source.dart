import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/utils/date_utils.dart';

/// Max aura a non-mentor may give per (UTC) day. Mirrored in firestore.rules.
const auraDailyLimit = 2;

/// Thrown when a non-mentor exceeds [auraDailyLimit] in a day.
class DailyLimitException implements Exception {
  const DailyLimitException();
}

/// Award writes against Firestore: read recipients, write a transaction and
/// atomically increment the recipient's aura counters.
abstract class AwardRemoteDataSource {
  Future<List<UserModel>> getAllUsers();

  /// Writes the award + recipient increment. Non-mentors also advance a daily
  /// quota counter (rejected past [auraDailyLimit]).
  Future<void> award(AuraTransaction txn, {required bool isMentor});
}

class AwardRemoteDataSourceImpl implements AwardRemoteDataSource {
  final FirebaseFirestore _db;
  AwardRemoteDataSourceImpl(this._db);

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snap = await _db.collection('users').limit(200).get();
    final users =
        snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
    users.sort((a, b) => a.displayName.compareTo(b.displayName));
    return users;
  }

  @override
  Future<void> award(AuraTransaction txn, {required bool isMentor}) async {
    final txnRef = _db.collection('aura_transactions').doc(txn.id);
    final toRef = _db.collection('users').doc(txn.toUserId);

    // Mentors: no quota — a plain batch is enough.
    if (isMentor) {
      final batch = _db.batch();
      batch.set(txnRef, txn.toMap());
      batch.update(toRef, {
        'currentWeekAura': FieldValue.increment(txn.points),
        'totalAura': FieldValue.increment(txn.points),
      });
      await batch.commit();
      return;
    }

    // Non-mentors: read-modify-write the quota counter atomically. Resets on a
    // new UTC day; rejects once the daily limit is hit. firestore.rules enforce
    // the same cap server-side.
    final fromRef = _db.collection('users').doc(txn.fromUserId);
    final today = DateUtils.currentDayKeyUtc();

    await _db.runTransaction((tx) async {
      final fromSnap = await tx.get(fromRef);
      final data = fromSnap.data() ?? const {};
      final sameDay = (data['awardDay'] as int? ?? 0) == today;
      final used = sameDay ? (data['awardCount'] as int? ?? 0) : 0;
      if (used >= auraDailyLimit) throw const DailyLimitException();

      tx.set(txnRef, txn.toMap());
      tx.update(toRef, {
        'currentWeekAura': FieldValue.increment(txn.points),
        'totalAura': FieldValue.increment(txn.points),
      });
      tx.update(fromRef, {
        'awardDay': today,
        'awardCount': used + 1,
      });
    });
  }
}
