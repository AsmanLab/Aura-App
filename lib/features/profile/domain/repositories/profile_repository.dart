import 'dart:typed_data';

import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/heart_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel?> getUser(String id);
  Future<List<AuraTransaction>> getHistory(String userId);
  Future<List<HeartTransaction>> getHeartHistory(String userId);
  Stream<List<AuraTransaction>> watchHistory(String userId);
  Stream<UserModel?> watchUser(String id);

  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoURL,
  });

  Future<String> uploadPhoto(String uid, Uint8List bytes);
}
