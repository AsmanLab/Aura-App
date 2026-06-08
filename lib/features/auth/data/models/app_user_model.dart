import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.displayName,
    required super.email,
    super.photoURL,
  });

  factory AppUserModel.fromFirebaseUser(User user) => AppUserModel(
        id: user.uid,
        displayName: user.displayName ?? 'Anonymous',
        email: user.email ?? '',
        photoURL: user.photoURL,
      );
}
