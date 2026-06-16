import 'package:aura_app/core/models/enums.dart';
import 'package:aura_app/core/models/user_model.dart';

abstract class AwardRepository {
  /// The signed-in giver (for role gating + denormalized name/photo).
  Future<UserModel?> getMe();

  /// Users the giver can award (everyone except self).
  Future<List<UserModel>> getRecipients();

  /// Writes the award + increments the recipient's aura.
  /// Non-mentors are capped at ±1 and a daily quota. [category] is optional.
  Future<void> award({
    required String toUserId,
    required int points,
    required String comment,
    AuraCategory? category,
  });
}
