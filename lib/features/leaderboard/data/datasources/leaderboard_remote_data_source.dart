import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/models/enums.dart';

const _demoMode = bool.fromEnvironment('DEMO', defaultValue: true);

/// Reads users and aggregates this month's aura for the leaderboard.
abstract class LeaderboardRemoteDataSource {
  Stream<List<UserModel>> watchUsers();

  /// Sum of aura points received per user since the start of this month.
  Stream<Map<String, int>> watchMonthlyTotals();
}

class LeaderboardRemoteDataSourceImpl implements LeaderboardRemoteDataSource {
  final FirebaseFirestore? _db;
  LeaderboardRemoteDataSourceImpl(this._db);

  static final _demoUserController =
      StreamController<List<UserModel>>.broadcast();

  static List<UserModel> _demoUserSnapshot = _initDemoUsers();

  static List<UserModel> _initDemoUsers() {
    final users = <UserModel>[
      UserModel(
        id: 'demo-user',
        displayName: 'Test User',
        email: 'test@example.com',
        photoURL: null,
        currentWeekAura: 120,
        totalAura: 540,
        role: Role.admin,
        hearts: 8,
        lastRouletteDate: null,
        awardDay: 0,
        awardCount: 0,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'user-1',
        displayName: 'Aibek Tashmatov',
        email: 'aibek@example.com',
        photoURL: null,
        currentWeekAura: 90,
        totalAura: 420,
        role: Role.mentor,
        hearts: 8,
        lastRouletteDate: null,
        awardDay: 0,
        awardCount: 0,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'user-2',
        displayName: 'Karina S.',
        email: 'karina@example.com',
        photoURL: null,
        currentWeekAura: 75,
        totalAura: 310,
        role: Role.fullTime,
        hearts: 8,
        lastRouletteDate: null,
        awardDay: 0,
        awardCount: 0,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'user-3',
        displayName: 'Danial B.',
        email: 'danial@example.com',
        photoURL: null,
        currentWeekAura: 60,
        totalAura: 280,
        role: Role.intern,
        hearts: 8,
        lastRouletteDate: null,
        awardDay: 0,
        awardCount: 0,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'user-4',
        displayName: 'Aisha M.',
        email: 'aisha@example.com',
        photoURL: null,
        currentWeekAura: 45,
        totalAura: 195,
        role: Role.intern,
        hearts: 8,
        lastRouletteDate: null,
        awardDay: 0,
        awardCount: 0,
        createdAt: DateTime.now(),
      ),
      UserModel(
        id: 'user-5',
        displayName: 'Bektur A.',
        email: 'bektur@example.com',
        photoURL: null,
        currentWeekAura: 0,
        totalAura: 0,
        role: Role.unknown,
        hearts: 8,
        lastRouletteDate: null,
        awardDay: 0,
        awardCount: 0,
        createdAt: DateTime.now(),
      ),
    ];
    _demoUserController.add(users);
    return users;
  }

  @override
  Stream<List<UserModel>> watchUsers() {
    if (_demoMode) {
      return _demoUsersStream();
    }
    return _db!
        .collection('users')
        .limit(200)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  static Stream<List<UserModel>> _demoUsersStream() {
    final controller = StreamController<List<UserModel>>();
    final snapshot = _demoUserSnapshot;
    final sub = _demoUserController.stream.listen(controller.add, onError: controller.addError);
    controller.add(snapshot);
    controller.onCancel = () async => await sub.cancel();
    return controller.stream;
  }

  static void updateDemoUsers(List<UserModel> updated) {
    _demoUserSnapshot = updated;
    _demoUserController.add(updated);
  }

  static List<UserModel> get demoUsersSnapshot =>
      List.unmodifiable(_demoUserSnapshot);

  @override
  Stream<Map<String, int>> watchMonthlyTotals() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    if (_demoMode) {
      return Stream.value({
        'demo-user': 240,
        'user-1': 180,
        'user-2': 150,
        'user-3': 90,
        'user-4': 40,
        'user-5': 0,
      });
    }

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
