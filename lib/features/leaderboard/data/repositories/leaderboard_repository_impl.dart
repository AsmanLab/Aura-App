import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../datasources/leaderboard_remote_data_source.dart';

const _demoMode = bool.fromEnvironment('DEMO', defaultValue: true);

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final LeaderboardRemoteDataSource _remote;
  final FirebaseAuth? _auth;

  LeaderboardRepositoryImpl(this._remote, this._auth);

  @override
  Stream<List<LeaderboardEntry>> watchLeaderboard(LbFilter filter) {
    if (_demoMode) {
      return _remote.watchUsers().map((users) {
        return _rank(
          users.map(
            (u) => LeaderboardEntry(
              u,
              filter == LbFilter.week ? u.currentWeekAura : u.totalAura,
            ),
          ),
        );
      });
    }

    if (filter != LbFilter.month) {
      return _remote.watchUsers().map((users) {
        return _rank(
          users.map(
            (u) => LeaderboardEntry(
              u,
              filter == LbFilter.week ? u.currentWeekAura : u.totalAura,
            ),
          ),
        );
      });
    }

    late StreamController<List<LeaderboardEntry>> controller;
    StreamSubscription<List<UserModel>>? usersSub;
    StreamSubscription<Map<String, int>>? monthlySub;
    List<UserModel>? latestUsers;
    Map<String, int>? latestMonthly;

    void emitIfReady() {
      final users = latestUsers;
      final monthly = latestMonthly;
      if (users == null || monthly == null || controller.isClosed) return;

      controller.add(
        _rank(users.map((u) => LeaderboardEntry(u, monthly[u.id] ?? 0))),
      );
    }

    controller = StreamController<List<LeaderboardEntry>>(
      onListen: () {
        usersSub = _remote.watchUsers().listen((users) {
          latestUsers = users;
          emitIfReady();
        }, onError: controller.addError);
        monthlySub = _remote.watchMonthlyTotals().listen((monthly) {
          latestMonthly = monthly;
          emitIfReady();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await usersSub?.cancel();
        await monthlySub?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }

  List<LeaderboardEntry> _rank(Iterable<LeaderboardEntry> entries) {
    final ranked = entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.user.displayName.compareTo(b.user.displayName);
      });
    return ranked.take(50).toList();
  }

  @override
  String? get currentUserId =>
      _demoMode ? 'demo-user' : _auth?.currentUser?.uid;
}
