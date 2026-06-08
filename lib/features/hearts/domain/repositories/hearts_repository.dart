import 'package:aura_app/core/models/user_model.dart';

abstract class HeartsRepository {
  /// The signed-in giver (for role gating + denormalized name/photo).
  Future<UserModel?> getMe();

  /// Interns the mentor can give/remove hearts from (excluding self).
  Future<List<UserModel>> getRecipients();

  /// Add (+1) or remove (-1) a heart. Removing requires a comment.
  /// Throws if the giver can't award, on self-target, or out of bounds.
  Future<void> changeHeart({
    required String toUserId,
    required int delta,
    required String comment,
  });
}
