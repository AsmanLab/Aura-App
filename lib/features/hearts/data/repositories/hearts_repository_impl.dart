import 'package:uuid/uuid.dart';

import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import 'package:aura_app/core/utils/date_utils.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/hearts_repository.dart';
import '../datasources/hearts_remote_data_source.dart';

class HeartsRepositoryImpl implements HeartsRepository {
  final HeartsRemoteDataSource _remote;
  final AuthRepository _auth;
  final _uuid = const Uuid();

  HeartsRepositoryImpl(this._remote, this._auth);

  @override
  Future<UserModel?> getMe() => _auth.getUser();

  @override
  Future<List<UserModel>> getRecipients() async {
    final me = await _auth.getUser();
    final interns = await _remote.getInterns();
    return interns.where((u) => u.id != me?.id).toList();
  }

  @override
  Future<void> changeHeart({
    required String toUserId,
    required int delta,
    required String comment,
  }) async {
    final me = await _auth.getUser();
    if (me == null) throw Exception('Not signed in');
    if (!me.canAward) throw Exception('Only mentors can change hearts');
    if (me.id == toUserId) throw Exception('Cannot change your own hearts');
    if (delta < 0 && comment.trim().isEmpty) {
      throw Exception('A comment is required to remove a heart');
    }

    final txn = HeartTransaction(
      id: _uuid.v4(),
      fromUserId: me.id,
      fromName: me.displayName,
      fromPhotoURL: me.photoURL,
      toUserId: toUserId,
      delta: delta,
      comment: comment.trim(),
      timestamp: DateTime.now(),
      weekId: DateUtils.getCurrentWeekId(),
    );
    await _remote.changeHeart(txn);
  }
}
