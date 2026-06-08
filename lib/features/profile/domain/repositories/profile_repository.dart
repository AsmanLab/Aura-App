import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel?> getUser(String id);
  Future<List<AuraTransaction>> getHistory(String userId);
}
