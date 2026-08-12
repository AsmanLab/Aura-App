import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:aura_app/core/domain/entities/aura_entry.dart';
import 'package:aura_app/core/domain/entities/person.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';

/// Reads real people from Firestore `users` collection.
/// Maps [UserModel] → [Person]. No seed data, no demo mode.
class FirebasePeopleRepository implements PeopleRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirebasePeopleRepository(this._db, this._auth);

  String? get _currentUid => _auth.currentUser?.uid;

  Person _toPerson(UserModel user, String? currentUid) {
    DateTime? trialStart;
    DateTime? trialEnd;
    final meta = user.metadata;
    final tsStart = meta['trialStart'];
    if (tsStart is Timestamp) trialStart = tsStart.toDate();
    final tsEnd = meta['trialEnd'];
    if (tsEnd is Timestamp) trialEnd = tsEnd.toDate();

    return Person(
      id: user.id,
      name: user.displayName,
      position: user.positionLabel,
      role: user.role,
      aura: user.totalAura,
      hearts: user.hearts,
      isYou: user.id == currentUid,
      trialStart: trialStart,
      trialEnd: trialEnd,
    );
  }

  @override
  Future<List<Person>> getPeople() async {
    final snap = await _db.collection('users').get();
    if (snap.docs.isEmpty) return [];

    final uid = _currentUid;
    return snap.docs
        .map((d) => _toPerson(UserModel.fromMap(d.data(), d.id), uid))
        .toList();
  }

  @override
  Future<Person> getMe() async {
    final uid = _currentUid;
    if (uid == null) throw Exception('No authenticated user');
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User profile not found for uid: $uid');
    return _toPerson(UserModel.fromMap(doc.data()!, doc.id), uid);
  }

  @override
  Future<Person> getOnDuty() async {
    Person? candidate;

    try {
      final dutyDoc = await _db.collection('duty').doc('current').get();
      if (dutyDoc.exists) {
        final personId = dutyDoc.data()!['personId'] as String?;
        if (personId != null && personId.isNotEmpty) {
          final userDoc = await _db.collection('users').doc(personId).get();
          if (userDoc.exists) {
            candidate = _toPerson(
              UserModel.fromMap(userDoc.data()!, userDoc.id),
              _currentUid,
            );
          }
        }
      }
    } catch (_) {}

    if (candidate == null) {
      try {
        final now = DateTime.now().toUtc();
        final dayStr = _dayName(now);
        final dateStr =
            '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final weekSnap = await _db
            .collection('duty_week')
            .where('day', isEqualTo: dayStr)
            .where('date', isEqualTo: dateStr)
            .limit(1)
            .get();
        if (weekSnap.docs.isNotEmpty) {
          final personId = weekSnap.docs.first.data()['personId'] as String?;
          if (personId != null) {
            final userDoc = await _db.collection('users').doc(personId).get();
            if (userDoc.exists) {
              candidate = _toPerson(
                UserModel.fromMap(userDoc.data()!, userDoc.id),
                _currentUid,
              );
            }
          }
        }
      } catch (_) {}
    }

    if (candidate != null && candidate.role == Role.intern) return candidate;

    final internsSnap = await _db
        .collection('users')
        .where('role', isEqualTo: Role.intern.name)
        .limit(1)
        .get();
    if (internsSnap.docs.isNotEmpty) {
      final doc = internsSnap.docs.first;
      return _toPerson(UserModel.fromMap(doc.data(), doc.id), _currentUid);
    }

    throw Exception('No intern found in Firestore');
  }

  @override
  Future<Person> getById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (!doc.exists) throw Exception('Person not found: $id');
    return _toPerson(UserModel.fromMap(doc.data()!, doc.id), _currentUid);
  }

  @override
  Future<List<Person>> getLeaderboard(LbFilter filter) async {
    final snap = await _db.collection('users').get();
    final interns = snap.docs
        .map((d) => _toPerson(UserModel.fromMap(d.data(), d.id), _currentUid))
        .where((p) => p.role == Role.intern)
        .toList()
      ..sort((a, b) => b.aura.compareTo(a.aura));

    if (filter == LbFilter.allTime) return interns;

    return interns
        .map((p) => p.copyWith(aura: (p.aura * filter.scale).round()))
        .toList();
  }

  @override
  Future<List<AuraEntry>> getHistory(String personId) async {
    final snap = await _db
        .collection('aura_transactions')
        .where('toUserId', isEqualTo: personId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return snap.docs.asMap().entries.map((entry) {
      final i = entry.key;
      final data = entry.value.data();
      final tx = AuraTransaction.fromMap(data, entry.value.id);
      final category =
          AuraCategory.values.asNameMap()[tx.category] ?? AuraCategory.helping;
      return AuraEntry(
        id: i + 1,
        category: category,
        points: tx.points,
        byPersonId: tx.fromUserId,
        reason: tx.comment,
        when: _timeAgo(tx.timestamp),
        linearId: null,
      );
    }).toList();
  }

  static String _dayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
