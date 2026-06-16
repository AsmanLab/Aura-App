import 'package:uuid/uuid.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/utils/date_utils.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/award_repository.dart';
import '../datasources/award_remote_data_source.dart'
    show AwardRemoteDataSource, DailyLimitException, auraDailyLimit;

class AwardRepositoryImpl implements AwardRepository {
  final AwardRemoteDataSource _remote;
  final AuthRepository _auth;
  final _uuid = const Uuid();

  AwardRepositoryImpl(this._remote, this._auth);

  @override
  Future<UserModel?> getMe() => _auth.getUser();

  @override
  Future<List<UserModel>> getRecipients() async {
    final me = await _auth.getUser();
    final all = await _remote.getAllUsers();
    return all.where((u) => u.id != me?.id).toList();
  }

  @override
  Future<void> award({
    required String toUserId,
    required int points,
    required String comment,
    required AuraCategory category,
  }) async {
    final me = await _auth.getUser();
    if (me == null) throw Exception('Not signed in');
    // Anyone signed in can give aura; only the self-award is blocked.
    if (me.id == toUserId) throw Exception('Cannot award yourself');

    // Non-mentors are capped at ±1 (also enforced in firestore.rules).
    final limit = me.canAward ? 10 : 1;
    final clamped = points.clamp(-limit, limit);

    final txn = AuraTransaction(
      id: _uuid.v4(),
      fromUserId: me.id,
      fromName: me.displayName,
      fromPhotoURL: me.photoURL,
      toUserId: toUserId,
      points: clamped,
      comment: comment.trim(),
      category: category.name,
      timestamp: DateTime.now(),
      weekId: DateUtils.getCurrentWeekId(),
    );
    try {
      await _remote.award(txn, isMentor: me.canAward);
    } on DailyLimitException {
      throw Exception(
        "You've reached your daily limit of $auraDailyLimit aura. "
        'Try again tomorrow.',
      );
    }
  }
}
