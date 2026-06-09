import 'package:uuid/uuid.dart';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/utils/date_utils.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/award_repository.dart';
import '../datasources/award_remote_data_source.dart';

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

    final txn = AuraTransaction(
      id: _uuid.v4(),
      fromUserId: me.id,
      fromName: me.displayName,
      fromPhotoURL: me.photoURL,
      toUserId: toUserId,
      points: points,
      comment: comment.trim(),
      category: category.name,
      timestamp: DateTime.now(),
      weekId: DateUtils.getCurrentWeekId(),
    );
    await _remote.award(txn);
  }
}
